# frozen_string_literal: true

require "rails_helper"

# L'éditeur de fiche de ceinture, de la fiche de l'élève jusqu'à l'exercice de
# chaque compétence. Et le cloisonnement : une fiche est celle d'un élève, que
# seuls voient ceux qui voient sa classe.
RSpec.describe "Fiches de ceinture", type: :request do
  let(:school) { create(:school) }
  let(:enseignant) { create(:user, school:, admin: false) }
  let(:grade) { create(:grade, school:, name: "CE1", grade_level: "CE1") }
  let(:classroom) { create(:classroom, user: enseignant, grade:, belt_sheets: true) }
  let(:eleve) { create(:student, classroom:, first_name: "Machin") }
  let!(:numeration) { create(:domain, grade:, position: 1, name: "Numération", special: false) }
  let!(:compter) { create(:skill, domain: numeration, level: 1, school:, name: "Compter jusqu'à 10") }
  let!(:ranger) { create(:skill, domain: numeration, level: 1, school:, name: "Ranger les nombres") }

  before { sign_in enseignant }

  def fiche
    BeltSheet.where(student: eleve).sole
  end

  it "garde le prénom de l'élève sous le titre d'une fiche renommée" do
    post student_belt_sheets_path(eleve)
    patch belt_sheet_path(fiche), params: { belt_sheet: { name: "Ceintures de novembre" } }

    get belt_sheet_path(fiche)
    page = Nokogiri::HTML(response.body)
    expect(page.at_css("h1.wp-title .wp-title-name").text).to eq("Ceintures de novembre")
    expect(page.at_css("h4.date-domain").text).to start_with("Machin · préparée le")
    get belt_sheets_path
    expect(response.body).to include("Ceintures de novembre")
  end

  it "prépare la fiche depuis la fiche de l'élève, et l'ouvre" do
    epreuve = create(:challenge, skill: compter, user: enseignant, for_belt: true, name: "Épreuve compter")

    post student_belt_sheets_path(eleve)

    expect(response).to redirect_to(belt_sheet_path(fiche))
    follow_redirect!
    expect(response.body).to include("Fiche de ceinture — Machin", "Numération", "Compter jusqu&#39;à 10",
                                     "Épreuve compter")
    expect(fiche.belt_sheet_skills.find_by!(skill: compter).challenge).to eq(epreuve)
  end

  it "propose Charger / Créer quand une compétence n'a pas d'exercice de ceinture, et crée l'exercice vide" do
    post student_belt_sheets_path(eleve)
    ligne = fiche.belt_sheet_skills.find_by!(skill: ranger)

    get belt_sheet_path(fiche)
    expect(response.body).to include(create_empty_challenge_belt_sheet_skill_path(ligne))

    post create_empty_challenge_belt_sheet_skill_path(ligne), as: :turbo_stream

    expect(ligne.reload.challenge).to be_for_belt
    expect(ligne.challenge.skill).to eq(ranger)
  end

  it "charge un autre exercice de ceinture depuis le carrousel" do
    premier = create(:challenge, skill: compter, user: enseignant, for_belt: true)
    autre = create(:challenge, skill: compter, user: enseignant, for_belt: true)
    post student_belt_sheets_path(eleve)
    ligne = fiche.belt_sheet_skills.find_by!(skill: compter)
    expect(ligne.challenge).to eq(premier)

    post pick_challenge_belt_sheet_skill_path(ligne), as: :turbo_stream
    expect(response.body).to include(autre.name)

    patch belt_sheet_skill_path(ligne), params: { belt_sheet_skill: { challenge_id: autre.id } }, as: :turbo_stream
    expect(ligne.reload.challenge).to eq(autre)
  end

  it "refuse un exercice classique, ou celui d'une autre compétence, dans une ligne" do
    post student_belt_sheets_path(eleve)
    ligne = fiche.belt_sheet_skills.find_by!(skill: compter)

    classique = create(:challenge, skill: compter, user: enseignant)
    ailleurs = create(:challenge, skill: ranger, user: enseignant, for_belt: true)

    [classique, ailleurs].each do |intrus|
      expect do
        patch belt_sheet_skill_path(ligne), params: { belt_sheet_skill: { challenge_id: intrus.id } }, as: :turbo_stream
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
    expect(ligne.reload.challenge).to be_nil
  end

  it "clone l'exercice de la ligne et met la copie à sa place" do
    epreuve = create(:challenge, skill: compter, user: enseignant, for_belt: true)
    post student_belt_sheets_path(eleve)
    ligne = fiche.belt_sheet_skills.find_by!(skill: compter)

    expect { post clone_challenge_belt_sheet_skill_path(ligne), as: :turbo_stream }.to change(Challenge, :count).by(1)

    expect(ligne.reload.challenge).not_to eq(epreuve)
    expect(ligne.challenge).to be_for_belt
  end

  it "ajoute un domaine à la ceinture qui suit la dernière validée, et le range à sa place" do
    grammaire = create(:domain, grade:, position: 0, name: "Grammaire", special: false)
    verbe = create(:skill, domain: grammaire, level: 2, school:, name: "Le verbe")
    create(:belt, student: eleve, domain: grammaire, level: 1, completed: true)
    post student_belt_sheets_path(eleve)

    get new_belt_sheet_belt_sheet_domain_path(fiche)
    pastille = Nokogiri::HTML(response.body).at_css("input[value='#{grammaire.id}']").parent
    expect(pastille.at_css("i.fa-bacon.belt-2")).to be_present
    expect(response.body).not_to include("belt_sheet_domain[level]")

    # Une ceinture glissée dans la requête n'est pas lue : c'est la N+1.
    post belt_sheet_belt_sheet_domains_path(fiche),
         params: { belt_sheet_domain: { domain_id: grammaire.id, level: 5 } }, as: :turbo_stream

    bloc = fiche.belt_sheet_domains.find_by!(domain: grammaire)
    expect(bloc.level).to eq(2)
    expect(bloc.belt_sheet_skills.map(&:skill)).to eq([verbe])
    expect(fiche.ordered_domains.map(&:domain)).to eq([grammaire, numeration])
  end

  it "n'ajoute rien pour un domaine dont l'élève a déjà la noire" do
    7.times { |i| create(:belt, student: eleve, domain: numeration, level: i + 1, completed: true) }
    post student_belt_sheets_path(eleve), params: { belt_sheet: { domain_ids: [""] } }

    post belt_sheet_belt_sheet_domains_path(fiche), params: { belt_sheet_domain: { domain_id: numeration.id } },
                                                    as: :turbo_stream

    expect(fiche.belt_sheet_domains).to be_empty
    expect(response.body).to include("Toutes les ceintures de Numération sont déjà validées")
  end

  it "retire puis remet une compétence, et retire un domaine" do
    post student_belt_sheets_path(eleve)
    bloc = fiche.belt_sheet_domains.sole
    ligne = bloc.belt_sheet_skills.find_by!(skill: ranger)

    delete belt_sheet_skill_path(ligne), as: :turbo_stream
    expect(bloc.belt_sheet_skills.reload.map(&:skill)).to eq([compter])

    post belt_sheet_domain_belt_sheet_skills_path(bloc), params: { skill_id: ranger.id }, as: :turbo_stream
    expect(bloc.belt_sheet_skills.reload.map(&:skill)).to eq([compter, ranger])

    delete belt_sheet_domain_path(bloc), as: :turbo_stream
    expect(fiche.belt_sheet_domains).to be_empty
  end

  it "refuse d'ajouter à un bloc la compétence d'une autre ceinture" do
    post student_belt_sheets_path(eleve)
    bloc = fiche.belt_sheet_domains.sole
    autre_ceinture = create(:skill, domain: numeration, level: 3, school:, name: "Plus tard")

    expect do
      post belt_sheet_domain_belt_sheet_skills_path(bloc), params: { skill_id: autre_ceinture.id }, as: :turbo_stream
    end.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "ouvre le PDF par sa page d'attente, depuis le bouton de la fiche" do
    post student_belt_sheets_path(eleve)

    get belt_sheet_path(fiche)
    expect(response.body).to include(export_belt_sheet_path(fiche))

    get export_belt_sheet_path(fiche)
    expect(response.body).to include("Génération de la fiche de ceinture", belt_sheet_path(fiche, format: :pdf))
  end

  describe "la modale de préparation" do
    let!(:geometrie) { create(:domain, grade:, position: 2, name: "Géométrie", special: true) }
    let!(:grammaire) { create(:domain, grade:, position: 3, name: "Grammaire", special: false) }

    before { create(:skill, domain: grammaire, level: 1, school:, name: "Le verbe") }

    it "propose les domaines du niveau, cochés sauf les spéciaux" do
      get student_new_belt_sheet_modal_path(eleve)

      cases = Nokogiri::HTML(response.body).css("input[type=checkbox][name='belt_sheet[domain_ids][]']")
      cochees = cases.select { |c| c.key?("checked") }.map { |c| c["value"].to_i }
      expect(cases.map { |c| c["value"].to_i }).to contain_exactly(numeration.id, geometrie.id, grammaire.id)
      expect(cochees).to contain_exactly(numeration.id, grammaire.id)
    end

    it "ne prépare que les domaines cochés, et un domaine spécial coché arrive vide" do
      post student_belt_sheets_path(eleve), params: { belt_sheet: { domain_ids: ["", numeration.id, geometrie.id] } }

      blocs = fiche.ordered_domains
      expect(blocs.map(&:domain)).to eq([numeration, geometrie])
      expect(blocs.last.belt_sheet_skills).to be_empty
    end

    context "avec une ceinture en cours" do
      let(:verbe) { Skill.find_by!(name: "Le verbe") }

      before do
        wpd = create(:work_plan_domain, work_plan: create(:work_plan, user: enseignant, student: eleve, grade:),
                                        domain: grammaire, level: 1)
        WorkPlanSkill.create!(skill: verbe, work_plan_domain: wpd, kind: "ceinture", status: "new")
      end

      it "s'ouvre sur les ceintures des plans, coche les domaines qui en ont une, et montre les deux aperçus" do
        get student_new_belt_sheet_modal_path(eleve)

        page = Nokogiri::HTML(response.body)
        cochees = page.css("input[type=checkbox][checked]").map { |c| c["value"].to_i }
        expect(cochees).to eq([grammaire.id])
        ligne = page.at_css("#belt_sheet_domain_#{grammaire.id}").parent
        expect(ligne["data-en-cours"]).to eq("true")
        expect(ligne.at_css("[data-mode=en_cours]").text.squish).to eq("Ceinture blanche · 1 compétence")
        expect(ligne.at_css("[data-mode=resultats]").text.squish).to eq("Ceinture blanche · 1 compétence")
        geo = page.at_css("#belt_sheet_domain_#{geometrie.id}").parent
        expect(geo.at_css("[data-mode=en_cours]").text.squish).to eq("rien de prévu")
        expect(geo.at_css("[data-mode=resultats]").text.squish).to eq("Ceinture blanche · à garnir à la main")
        modes = page.css("input[type=radio][name=mode]")
        expect(modes.map { |m| m["value"] }).to contain_exactly("en_cours", "resultats")
        expect(modes.find { |m| m.key?("checked") }["value"]).to eq("en_cours")
      end

      it "prépare les ceintures en cours avec le bouton du même nom" do
        post student_belt_sheets_path(eleve), params: { mode: "en_cours", belt_sheet: { domain_ids: [grammaire.id] } }

        expect(fiche.belt_sheet_skills.map(&:skill)).to eq([verbe])
      end

      it "retombe sur « selon les résultats » pour un mode inconnu" do
        post student_belt_sheets_path(eleve), params: { mode: "nimporte", belt_sheet: { domain_ids: [numeration.id] } }

        expect(fiche.belt_sheet_skills.map(&:skill)).to contain_exactly(compter, ranger)
      end
    end

    it "ignore un domaine d'un autre niveau glissé dans la requête" do
      ailleurs = create(:domain, grade: create(:grade, school:, name: "CM1", grade_level: "CM1"), name: "Ailleurs")

      post student_belt_sheets_path(eleve), params: { belt_sheet: { domain_ids: [ailleurs.id, numeration.id] } }

      expect(fiche.belt_sheet_domains.map(&:domain)).to eq([numeration])
    end
  end

  describe "cloner une fiche" do
    let!(:camarade) { create(:student, classroom:, first_name: "Liam") }
    let!(:sans_ceintures) do
      create(:student, classroom: create(:classroom, user: enseignant, grade:, name: "Sans"), first_name: "Hors")
    end
    let!(:autre_niveau) do
      autre = create(:grade, school:, name: "CM1", grade_level: "CM1")
      create(:student, classroom: create(:classroom, user: enseignant, grade: autre, belt_sheets: true),
                       first_name: "Ailleurs")
    end

    before { post student_belt_sheets_path(eleve) }

    it "propose les élèves du même niveau, dans les classes aux fiches de ceinture" do
      get belt_sheet_clone_modal_path(fiche)

      noms = Nokogiri::HTML(response.body).css(".tag-item label").map(&:text)
      expect(noms).to eq(["Liam"])
    end

    it "crée une copie pour chaque élève coché, et ignore un élève hors des candidats" do
      expect do
        post clone_belt_sheet_path(fiche), params: { clone: { student_ids: ["", camarade.id, sans_ceintures.id] } }
      end.to change(BeltSheet, :count).by(1)

      copie = BeltSheet.find_by!(student: camarade)
      expect(copie.belt_sheet_skills.map(&:skill)).to eq(fiche.belt_sheet_skills.map(&:skill))
      expect(response).to redirect_to(belt_sheets_path)
      expect(flash[:notice]).to eq("Fiche clonée pour Liam.")
    end

    it "le dit quand aucun élève n'est coché" do
      expect { post clone_belt_sheet_path(fiche), params: { clone: { student_ids: [""] } } }.
        not_to change(BeltSheet, :count)
      expect(flash[:notice]).to include("Aucun élève coché")
    end
  end

  describe "le réglage de la classe" do
    it "refuse de préparer une fiche quand la classe n'a pas ouvert les fiches de ceinture" do
      classroom.update!(belt_sheets: false)

      expect { post student_belt_sheets_path(eleve) }.not_to change(BeltSheet, :count)
    end

    it "laisse lire une fiche déjà faite après qu'on a coupé le réglage" do
      post student_belt_sheets_path(eleve)
      classroom.update!(belt_sheets: false)

      get belt_sheet_path(fiche)
      expect(response).to have_http_status(:ok)
    end

    it "montre le menu Ceintures et la fiche de l'élève seulement avec le réglage" do
      get student_path(eleve)
      expect(response.body).to include(belt_sheets_path, student_new_belt_sheet_modal_path(eleve))

      classroom.update!(belt_sheets: false)
      get student_path(eleve)
      expect(response.body).not_to include(student_new_belt_sheet_modal_path(eleve))
      expect(response.body).not_to include(%(href="#{belt_sheets_path}"))
    end

    it "étiquette la fiche et le plan de travail, tant que la classe a ouvert les fiches" do
      plan = create(:work_plan, user: enseignant, student: eleve, grade:)
      post student_belt_sheets_path(eleve)
      etiquette = -> { Nokogiri::HTML(response.body).at_css(".ui-tag")&.text }

      get belt_sheet_path(fiche)
      expect(etiquette.call).to eq("Fiche de ceinture")
      get work_plan_path(plan)
      expect(etiquette.call).to eq("Plan de travail")

      classroom.update!(belt_sheets: false)
      get work_plan_path(plan)
      expect(etiquette.call).to be_nil
    end

    it "se règle depuis la modale de la classe" do
      classroom.update!(belt_sheets: false)

      patch classroom_path(classroom), params: { classroom: { name: "Les hiboux", belt_sheets: "1" } }

      expect(classroom.reload).to have_attributes(name: "Les hiboux", belt_sheets: true)
    end
  end

  describe "Voir > Ceintures" do
    it "range les fiches par élève, sous les classes qui ont le réglage" do
      autre_classe = create(:classroom, user: enseignant, grade:, name: "Sans ceintures")
      create(:student, classroom: autre_classe, first_name: "Personne")
      post student_belt_sheets_path(eleve)

      get belt_sheets_path

      expect(response.body).to include("Machin", "Fiche de ceinture", I18n.l(fiche.created_at.to_date, format: "%d/%m/%Y"))
      expect(response.body).not_to include("Sans ceintures", "Personne")
    end

    it "revient à la liste après la suppression d'une fiche" do
      post student_belt_sheets_path(eleve)

      delete belt_sheet_path(fiche), headers: { "HTTP_REFERER" => belt_sheets_url }

      expect(response).to redirect_to(belt_sheets_url)
      expect(BeltSheet.where(student: eleve)).to be_empty
    end
  end

  describe "fiches non assignées" do
    let(:filtres) { { "/challenges": { grade: grade.id, domain: numeration.id, level: 1 } } }

    # La classe aux fiches de ceinture, sans laquelle rien ne se génère : aucun
    # élève ne l'appelle ici.
    before { classroom }

    def generer(level: 1, domain: numeration, niveau: grade)
      post generer_belt_sheets_path(grade_id: niveau.id, domain_id: domain.id, level:)
    end

    def non_assignee
      BeltSheet.non_assignees.sole
    end

    it "se génère depuis les exercices de ceinture filtrés, et s'ouvre dans l'éditeur" do
      epreuve = create(:challenge, skill: compter, user: enseignant, for_belt: true, name: "Épreuve compter")

      get challenges_path(ceinture: 1, **filtres)
      bouton = Nokogiri::HTML(response.body).at_css("form[action='#{generer_belt_sheets_path(grade_id: grade.id,
                                                                                          domain_id: numeration.id,
                                                                                          level: 1)}']")
      expect(bouton.text).to include("Générer une fiche")

      generer

      expect(response).to redirect_to(belt_sheet_path(non_assignee))
      follow_redirect!
      page = Nokogiri::HTML(response.body)
      expect(page.at_css("h1.wp-title .wp-title-name").text).to eq("Numération blanche")
      expect(page.at_css("h4.date-domain").text).to start_with("CE1 · non assignée · préparée le")
      expect(response.body).to include("Épreuve compter", non_assignees_belt_sheets_path,
                                       export_belt_sheet_path(non_assignee))
      # Rien ne se distribue encore à des élèves.
      expect(response.body).not_to include(belt_sheet_clone_modal_path(non_assignee))
      expect(non_assignee.belt_sheet_skills.map(&:skill)).to eq([compter, ranger])
    end

    it "n'offre pas de générer une fiche depuis les exercices classiques" do
      get challenges_path(filtres)

      expect(response.body).not_to include("Générer une fiche")
    end

    it "refuse un domaine d'un autre niveau, ou une ceinture qui n'existe pas" do
      ailleurs = create(:domain, grade: create(:grade, school:, name: "CM1", grade_level: "CM1"), name: "Ailleurs")

      generer(level: 8)
      expect(response).to have_http_status(:unprocessable_content)
      # En dernier : la requête qui lève n'enregistre pas la session.
      expect { generer(domain: ailleurs) }.to raise_error(ActiveRecord::RecordNotFound)
      expect(BeltSheet.count).to eq(0)
    end

    it "refuse de générer sans classe aux fiches de ceinture, ou pour le niveau d'une autre école" do
      classroom.update!(belt_sheets: false)
      expect { generer }.not_to change(BeltSheet, :count)

      classroom.update!(belt_sheets: true)
      autre = create(:grade, school: create(:school), name: "CE1", grade_level: "CE1")
      domaine_autre = create(:domain, grade: autre, name: "Autre numération", special: false)
      expect { generer(niveau: autre, domain: domaine_autre) }.not_to change(BeltSheet, :count)
    end

    it "garnit à la main un domaine spécial, puis ajoute un domaine à la ceinture choisie" do
      geometrie = create(:domain, grade:, position: 2, name: "Géométrie", special: true)
      create(:skill, domain: geometrie, level: 1, school:, name: "Tracer")
      grammaire = create(:domain, grade:, position: 3, name: "Grammaire", special: false)
      verbe = create(:skill, domain: grammaire, level: 4, school:, name: "Le verbe")

      generer(domain: geometrie, level: 5)
      expect(non_assignee.belt_sheet_domains.sole).to have_attributes(level: 1, belt_sheet_skills: [])
      expect(flash[:notice]).to include("ajoutez les compétences")

      get new_belt_sheet_belt_sheet_domain_path(non_assignee)
      expect(response.body).to include("belt_sheet_domain[level]")

      post belt_sheet_belt_sheet_domains_path(non_assignee),
           params: { belt_sheet_domain: { domain_id: grammaire.id, level: 4 } }, as: :turbo_stream

      bloc = non_assignee.belt_sheet_domains.find_by!(domain: grammaire)
      expect(bloc.level).to eq(4)
      expect(bloc.belt_sheet_skills.map(&:skill)).to eq([verbe])
    end

    it "s'imprime sans prénom" do
      generer

      get export_belt_sheet_path(non_assignee)
      expect(response.body).to include(belt_sheet_path(non_assignee, format: :pdf))
    end

    it "se range par niveau dans son onglet, celles de l'enseignant seulement" do
      generer
      collegue = create(:user, school:, admin: false)
      grammaire = create(:domain, grade:, position: 3, name: "Grammaire", special: false)
      create(:skill, domain: grammaire, level: 1, school:, name: "Le verbe")
      BeltSheet.generer!(grade, grammaire, 1, collegue)

      get non_assignees_belt_sheets_path

      page = Nokogiri::HTML(response.body)
      expect(page.css(".wp-firstname").map(&:text)).to eq(["CE1"])
      expect(page.css(".namept").map { |n| n.text.squish }).to eq(["Numération blanche"])
      expect(page.at_css(".ui-tabs--secondary .ui-tabs-active").text).to eq("Non assignées")
      expect(response.body).not_to include("Machin")
    end

    it "se renomme depuis la modale de l'éditeur, comme un plan de travail" do
      generer

      get belt_sheet_path(non_assignee)
      champ = Nokogiri::HTML(response.body).at_css("#belt-sheet-edit-modal input[name='belt_sheet[name]']")
      expect(champ["value"]).to eq("Numération blanche")

      patch belt_sheet_path(non_assignee), params: { belt_sheet: { name: "Révisions de Toussaint" } }
      expect(response).to redirect_to(belt_sheet_path(non_assignee))
      expect(non_assignee.reload.nom).to eq("Révisions de Toussaint")

      get non_assignees_belt_sheets_path
      expect(Nokogiri::HTML(response.body).at_css(".namept").text).to eq("Révisions de Toussaint")

      # Vide, elle reprend son nom par défaut.
      patch belt_sheet_path(non_assignee), params: { belt_sheet: { name: "" } }
      expect(non_assignee.reload.nom).to eq("Numération blanche")
    end

    it "s'ouvre dans un nouvel onglet depuis les deux listes, comme un plan de travail" do
      generer
      post student_belt_sheets_path(eleve)

      [non_assignees_belt_sheets_path, belt_sheets_path].each do |liste|
        get liste
        liens = Nokogiri::HTML(response.body).css(".student-wp a")
        expect(liens).to be_present
        expect(liens.map { |lien| lien["target"] }.uniq).to eq(["_blank"])
      end
    end

    it "revient à son onglet après sa suppression depuis l'éditeur" do
      generer

      delete belt_sheet_path(non_assignee), headers: { "HTTP_REFERER" => belt_sheet_url(non_assignee) }

      expect(response).to redirect_to(non_assignees_belt_sheets_path)
      expect(BeltSheet.count).to eq(0)
    end

    it "reste fermée à un collègue de la même école" do
      generer
      fiche = non_assignee
      ligne = fiche.belt_sheet_skills.first
      sign_in create(:user, school:, admin: false)

      get belt_sheet_path(fiche)
      expect(response).to have_http_status(:redirect)
      expect { delete belt_sheet_path(fiche) }.not_to change(BeltSheet, :count)
      expect { post create_empty_challenge_belt_sheet_skill_path(ligne), as: :turbo_stream }.
        not_to change(Challenge, :count)
      get non_assignees_belt_sheets_path
      expect(response.body).not_to include("Numération blanche")
    end
  end

  describe "cloisonnement" do
    let(:autre_ecole) { create(:school) }
    let(:intrus) { create(:user, school: autre_ecole, admin: false) }

    it "ferme la fiche, ses blocs et ses lignes à l'enseignant d'une autre école" do
      post student_belt_sheets_path(eleve)
      bloc = fiche.belt_sheet_domains.sole
      ligne = bloc.belt_sheet_skills.first
      sign_in intrus

      get belt_sheet_path(fiche)
      expect(response).to have_http_status(:redirect)
      expect(response.body).not_to include("Machin")

      expect { post student_belt_sheets_path(eleve) }.not_to change(BeltSheet, :count)
      expect { delete belt_sheet_domain_path(bloc), as: :turbo_stream }.not_to change(BeltSheetDomain, :count)
      expect { post create_empty_challenge_belt_sheet_skill_path(ligne), as: :turbo_stream }.
        not_to change(Challenge, :count)
    end
  end
end
