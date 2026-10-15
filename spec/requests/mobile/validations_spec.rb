# frozen_string_literal: true

require "rails_helper"

# Sur la fiche mobile d'un élève, un appui sur la ceinture d'un domaine ouvre
# les compétences de la ceinture suivante ; chaque appui sur une compétence
# l'enregistre aussitôt.
RSpec.describe "Mobile::Validations", type: :request do
  let(:school) { create(:school) }
  let(:grade) { create(:grade, school:, name: "CE2", grade_level: "CE2") }
  let(:teacher) { create(:user, admin: false, demo: false) }
  let(:classroom) { create(:classroom, user: teacher, grade:) }
  let(:student) { create(:student, classroom:, first_name: "leo") }
  let(:domaine) { create(:domain, grade:, name: "Numération", special: false) }
  let!(:blanches) do
    %w[Lire Écrire Comparer].map.with_index(1) do |nom, position|
      create(:skill, domain: domaine, school:, level: 1, name: "#{nom} les nombres", position:)
    end
  end
  let!(:jaune) { create(:skill, domain: domaine, school:, level: 2, name: "Ranger les nombres") }

  let(:turbo) { { "Accept" => "text/vnd.turbo-stream.html" } }

  before do
    school.add_teacher(teacher)
    teacher.reload
    sign_in teacher
  end

  def valider(student, skill, origin: Result::DIRECT)
    create(:result, student:, skill:, kind: "ceinture", status: "completed", origin:)
  end

  def enregistrer(skill, validee:, level: 1, domain: domaine, eleve: student)
    patch mobile_student_domain_validation_path(eleve, domain),
          params: { validation: { skill_id: skill.id, validee:, level: } }, headers: turbo
  end

  def resultat(skill)
    Result.find_by(student:, skill:)
  end

  def ouvrir(domain = domaine)
    get edit_mobile_student_domain_validation_path(student, domain)
    Nokogiri::HTML(response.body)
  end

  describe "GET edit" do
    # Le layout mobile porte un cadre `general_modal` vide : rendu avec lui, la
    # réponse en contenait deux et Turbo ouvrait le premier, le vide.
    it "répond au cadre de la modale par un seul cadre, le sien" do
      get edit_mobile_student_domain_validation_path(student, domaine), headers: { "Turbo-Frame" => "general_modal" }

      cadres = Nokogiri::HTML(response.body).css("turbo-frame#general_modal")
      expect(cadres.size).to eq(1)
      expect(cadres.first.at_css(".mobile-feuille")).to be_present
    end

    it "propose la ceinture blanche à l'élève qui n'en a aucune" do
      ouvrir

      expect(response).to be_successful
      expect(response.body).to include("Ceinture blanche", "Numération · Leo")
      etiquette = Nokogiri::HTML(response.body).at_css(".ui-tag")
      expect(etiquette.text).to eq("En cours")
      expect(etiquette.at_css(".ui-tag-pastille.belt-bg-1")).to be_present
      expect(response.body).to include("Lire les nombres", "Écrire les nombres", "Comparer les nombres")
      expect(response.body).not_to include("Ranger les nombres")
      expect(response.body).to include("Aucune compétence validée sur 3")
    end

    it "propose la jaune une fois la blanche obtenue" do
      create(:belt, student:, domain: domaine, level: 1, completed: true, validated_date: Date.current)

      ouvrir

      expect(response.body).to include("Ceinture jaune", "Ranger les nombres")
      expect(response.body).not_to include("Lire les nombres")
    end

    it "fait de chaque ligne le bouton qui l'enregistre, avec l'état qu'elle vise" do
      ligne = ouvrir.at_css("#ligne_competence_#{blanches.first.id}")

      expect(ligne.at_css("form button.mobile-validation-ligne")["aria-pressed"]).to eq("false")
      expect(ligne.at_css("input[name='validation[validee]']")["value"]).to eq("true")
      expect(ligne.at_css("input[name='validation[level]']")["value"]).to eq("1")
      expect(ligne.at_css("input[name='_method']")["value"]).to eq("patch")
    end

    it "range les validées à la fin, et verrouille celles obtenues à l'évaluation" do
      valider(student, blanches.first)
      valider(student, blanches.second, origin: Result::EVALUATION)

      page = ouvrir

      expect(page.css(".mobile-validation-nom").map(&:text)).
        to eq(["Comparer les nombres", "Lire les nombres", "Écrire les nombres"])
      expect(response.body).to include("2 compétences validées sur 3", "Déjà validées")
      directe = page.at_css("#ligne_competence_#{blanches.first.id}")
      expect(directe.at_css("button")["class"].split).to include("--validee")
      expect(directe.at_css("button")["aria-pressed"]).to eq("true")
      expect(directe.at_css("input[name='validation[validee]']")["value"]).to eq("false")
      evaluee = page.at_css("#ligne_competence_#{blanches.second.id}")
      expect(evaluee.at_css("form")).to be_nil
      expect(evaluee.text).to include("Validée à l'évaluation")
    end

    it "dit quand toutes les ceintures sont obtenues" do
      create(:belt, student:, domain: domaine, level: 7, completed: true, validated_date: Date.current)

      ouvrir

      expect(response.body).to include("Ceinture noire", "Leo a obtenu toutes les ceintures de Numération.")
      expect(Nokogiri::HTML(response.body).at_css(".ui-tag").text).to eq("Obtenue")
      expect(response.body).not_to include("mobile-validation-ligne")
    end

    it "montre toutes les compétences d'un domaine spécial, et ce qu'il reste pour sa prochaine ceinture" do
      geometrie = create(:domain, grade:, name: "Géométrie", special: true)
      create_list(:skill, 4, domain: geometrie, school:, level: 1)
      valider(student, geometrie.skills.first)

      page = ouvrir(geometrie)

      expect(response.body).to include("Ceinture blanche")
      # Barème CE2 de la Géométrie : 2 compétences pour la blanche.
      expect(response.body).to include("1 compétence validée sur 4 · encore 1 pour la ceinture blanche")
      expect(page.css(".mobile-validation-ligne").size).to eq(4)
    end

    it "refuse l'élève d'une autre école" do
      ailleurs = create(:student, classroom: create(:classroom, grade: create(:grade, school: create(:school))))

      get edit_mobile_student_domain_validation_path(ailleurs, domaine)

      expect(response).to redirect_to(dashboard_path)
    end

    it "ne sert pas le domaine d'un autre niveau" do
      autre_niveau = create(:domain, grade: create(:grade, school:, name: "CM1", grade_level: "CM1"), name: "Calcul")

      expect do
        get edit_mobile_student_domain_validation_path(student, autre_niveau)
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "PATCH update" do
    it "valide la compétence touchée, comme le « + » de la grille de la classe" do
      enregistrer(blanches.first, validee: true)

      expect(resultat(blanches.first)).to have_attributes(kind: "ceinture", status: "completed",
                                                          origin: Result::DIRECT)
      expect(resultat(blanches.second)).to be_nil
      expect(Belt.completed.where(student:, domain: domaine)).to be_empty
    end

    it "redessine la ligne à sa place, l'en-tête et la ceinture du domaine" do
      enregistrer(blanches.first, validee: true)

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include('action="replace" target="validation-entete"')
      expect(response.body).to include(%(action="replace" target="ligne_competence_#{blanches.first.id}"))
      expect(response.body).to include(%(action="replace" target="mobile_ceinture_#{student.id}_#{domaine.id}"))
      expect(response.body).to include("1 compétence validée sur 3")
      ligne = Nokogiri::HTML(response.body).at_css("#ligne_competence_#{blanches.first.id}")
      expect(ligne.at_css("button")["aria-pressed"]).to eq("true")
    end

    it "retire la validation au second appui" do
      valider(student, blanches.first)

      enregistrer(blanches.first, validee: false)

      expect(resultat(blanches.first)).to be_nil
    end

    it "garde la validation obtenue à l'évaluation" do
      valider(student, blanches.first, origin: Result::EVALUATION)

      enregistrer(blanches.first, validee: false)

      expect(resultat(blanches.first)).to be_belt_validated
    end

    # Deux appuis rapprochés, ou un collègue qui a validé pendant que la modale
    # était ouverte : l'état voulu ne défait rien.
    it "ne retire pas une compétence qu'on demande de valider" do
      valider(student, blanches.first)

      enregistrer(blanches.first, validee: true)

      expect(resultat(blanches.first)).to be_belt_validated
    end

    describe "quand la dernière compétence tombe" do
      before do
        valider(student, blanches.first)
        valider(student, blanches.second)
        enregistrer(blanches.third, validee: true)
      end

      it "décerne la ceinture et la montre obtenue, sans passer à la suivante" do
        expect(Belt.completed.find_by(student:, domain: domaine, level: 1)).to be_present
        page = Nokogiri::HTML(response.body)
        tuile = page.at_css(".mobile-ceinture-tuile")
        expect(tuile["class"].split).to include("--obtenue")
        expect(tuile.at_css(".mobile-belt-bar.belt-bg-1")).to be_present
        expect(page.at_css("#validation-entete .ui-tag").text).to eq("Obtenue")
        expect(page.at_css("#validation-titre").text).to eq("Ceinture blanche")
        expect(response.body).to include("Passer à la ceinture jaune")
        expect(response.body).not_to include("Ranger les nombres")
      end

      it "verrouille ses compétences : la ceinture obtenue ne se défait pas d'ici" do
        expect(Nokogiri::HTML(response.body).css("form.mobile-validation-form")).to be_empty

        enregistrer(blanches.first, validee: false)

        expect(resultat(blanches.first)).to be_belt_validated
        expect(Belt.completed.find_by(student:, domain: domaine, level: 1)).to be_present
      end
    end

    # Ses ceintures se comptent, et la cascade ne les reprend jamais : retirer
    # sous le barème laissait une ceinture orange pour une compétence validée.
    describe "dans un domaine spécial" do
      let(:geometrie) { create(:domain, grade:, name: "Géométrie", special: true) }
      let(:competences) { create_list(:skill, 3, domain: geometrie, school:, level: 1) }

      # Barème CE2 de la Géométrie : 2 compétences pour la blanche.
      before { competences.each { |skill| enregistrer(skill, validee: true, domain: geometrie) } }

      it "retire ce qui dépasse le barème de la ceinture obtenue" do
        enregistrer(competences.first, validee: false, domain: geometrie)

        expect(resultat(competences.first)).to be_nil
        expect(Belt.completed.find_by(student:, domain: geometrie, level: 1)).to be_present
      end

      it "ne descend pas sous le barème de la ceinture obtenue" do
        enregistrer(competences.first, validee: false, domain: geometrie)
        enregistrer(competences.second, validee: false, domain: geometrie)

        expect(resultat(competences.second)).to be_belt_validated
        expect(Nokogiri::HTML(response.body).css("form.mobile-validation-form").size).to eq(1)
      end
    end

    it "ignore une compétence étrangère à la ceinture" do
      enregistrer(jaune, validee: true)

      expect(resultat(jaune)).to be_nil
    end

    it "refuse l'élève de la classe d'un collègue" do
      collegue = create(:user, admin: false, demo: false)
      school.add_teacher(collegue)
      voisin = create(:student, classroom: create(:classroom, user: collegue, grade:))

      enregistrer(blanches.first, validee: true, eleve: voisin)

      expect(Result.where(student: voisin)).to be_empty
    end
  end
end
