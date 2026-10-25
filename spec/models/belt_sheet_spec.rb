# frozen_string_literal: true

require "rails_helper"

RSpec.describe BeltSheet, type: :model do
  # Une école cohérente de bout en bout : la factory :skill tire sinon sa propre
  # école, et :domain un nom au hasard — parfois celui d'un domaine spécial.
  let(:school) { create(:school) }
  let(:user) { create(:user, school:) }
  let(:grade) { create(:grade, school:, name: "CE1", grade_level: "CE1") }
  let(:classroom) { create(:classroom, user:, grade:) }
  let(:student) { create(:student, classroom:) }
  let!(:numeration) { create(:domain, grade:, name: "Numération", position: 2, special: false) }
  let!(:grammaire) { create(:domain, grade:, name: "Grammaire", position: 1, special: false) }

  def competence(domain, level, name)
    create(:skill, domain:, level:, school:, name:)
  end

  describe ".prepare!" do
    it "propose la ceinture qui suit la dernière validée, avec ses compétences non validées" do
      create(:belt, student:, domain: numeration, level: 1, completed: true)
      create(:belt, student:, domain: numeration, level: 2, completed: true)
      a_faire = competence(numeration, 3, "Comparer")
      validee = competence(numeration, 3, "Ranger")
      competence(numeration, 4, "Plus tard")
      Result.create!(student:, skill: validee, kind: "ceinture", status: "completed")

      sheet = described_class.prepare!(student, user)

      bloc = sheet.belt_sheet_domains.find_by!(domain: numeration)
      expect(bloc.level).to eq(3)
      expect(bloc.belt_sheet_skills.map(&:skill)).to eq([a_faire])
    end

    it "part de la blanche quand rien n'est validé, et range les blocs dans l'ordre des domaines" do
      competence(numeration, 1, "Compter")
      competence(grammaire, 1, "Le verbe")

      sheet = described_class.prepare!(student, user)

      expect(sheet.ordered_domains.map { |bloc| [bloc.domain, bloc.level] }).
        to eq([[grammaire, 1], [numeration, 1]])
    end

    it "laisse de côté les domaines spéciaux, qu'on ajoute à la main" do
      geometrie = create(:domain, grade:, name: "Géométrie", position: 3, special: true)
      competence(geometrie, 1, "Tracer")

      sheet = described_class.prepare!(student, user)

      expect(sheet.belt_sheet_domains.where(domain: geometrie)).to be_empty
    end

    it "ajoute à la main un domaine spécial VIDE : l'enseignant choisit ses compétences" do
      geometrie = create(:domain, grade:, name: "Géométrie", position: 3, special: true)
      3.times { |i| competence(geometrie, 1, "Tracer #{i}") }
      sheet = described_class.prepare!(student, user)

      bloc = sheet.add_domain!(geometrie, 1)

      expect(bloc).to be_persisted
      expect(bloc.belt_sheet_skills).to be_empty
    end

    it "n'ajoute pas de bloc quand l'élève a tout validé, ni après la noire" do
      7.times { |i| create(:belt, student:, domain: numeration, level: i + 1, completed: true) }
      competence(numeration, 7, "Tout")

      expect(described_class.prepare!(student, user).belt_sheet_domains).to be_empty
    end

    it "n'écrit aucun résultat" do
      competence(numeration, 1, "Compter")

      expect { described_class.prepare!(student, user) }.not_to change(Result, :count)
    end
  end

  describe ".prepare! en mode « ceintures en cours »" do
    let(:work_plan) { create(:work_plan, user:, student:, grade:) }

    # Une compétence posée dans un plan de travail de l'élève, à un état donné.
    def poser(skill, kind:, status: "new", domain: skill.domain)
      wpd = create(:work_plan_domain, work_plan:, domain:, level: skill.level)
      WorkPlanSkill.create!(skill:, work_plan_domain: wpd, kind:, status:)
    end

    def preparer(**)
      described_class.prepare!(student, user, mode: "en_cours", **)
    end

    it "ne met que les compétences posées « ceinture » et pas encore passées" do
      en_cours = competence(numeration, 3, "Comparer")
      ratee = competence(numeration, 3, "Ranger")
      exercice = competence(numeration, 3, "Encadrer")
      poser(en_cours, kind: "ceinture")
      poser(ratee, kind: "ceinture", status: "redo")
      poser(exercice, kind: "exercice")

      bloc = preparer.belt_sheet_domains.sole
      expect([bloc.domain, bloc.level]).to eq([numeration, 3])
      expect(bloc.belt_sheet_skills.map(&:skill)).to eq([en_cours])
    end

    it "suit le dernier WPS : une ceinture repassée en exercice n'est plus en cours" do
      skill = competence(numeration, 2, "Comparer")
      poser(skill, kind: "ceinture").update_column(:updated_at, 2.days.ago)
      poser(skill, kind: "exercice")

      expect(preparer.belt_sheet_domains).to be_empty
    end

    it "prend aussi les domaines spéciaux, avec leurs compétences en cours" do
      geometrie = create(:domain, grade:, name: "Géométrie", position: 3, special: true)
      tracer = competence(geometrie, 1, "Tracer")
      competence(geometrie, 1, "Mesurer")
      poser(tracer, kind: "ceinture")

      bloc = preparer.belt_sheet_domains.sole
      expect(bloc.belt_sheet_skills.map(&:skill)).to eq([tracer])
    end

    it "garnit un domaine coché sans ceinture en cours comme selon les résultats" do
      poser(competence(numeration, 1, "Compter"), kind: "ceinture")
      verbe = competence(grammaire, 1, "Le verbe")
      adjectif = competence(grammaire, 1, "L'adjectif")
      # Après les autres : seule de sa ceinture, elle la validait entière.
      Result.create!(student:, skill: competence(grammaire, 1, "Le nom"), kind: "ceinture", status: "completed")

      sheet = preparer(domains: [numeration, grammaire])

      grammaire_bloc, numeration_bloc = sheet.ordered_domains
      expect([grammaire_bloc.domain, grammaire_bloc.level]).to eq([grammaire, 1])
      expect(grammaire_bloc.belt_sheet_skills.map(&:skill)).to contain_exactly(verbe, adjectif)
      expect(numeration_bloc.belt_sheet_skills.size).to eq(1)
    end

    it "garde vide un domaine spécial coché sans ceinture en cours" do
      geometrie = create(:domain, grade:, name: "Géométrie", position: 3, special: true)
      competence(geometrie, 1, "Tracer")

      bloc = preparer(domains: [geometrie]).belt_sheet_domains.sole

      expect([bloc.level, bloc.belt_sheet_skills]).to eq([1, []])
    end
  end

  describe ".apercu" do
    it "dit, domaine par domaine, ce que chaque façon de préparer mettrait — sans rien enregistrer" do
      create(:belt, student:, domain: numeration, level: 1, completed: true)
      prevue = competence(numeration, 2, "Comparer")
      competence(numeration, 2, "Ranger")
      wpd = create(:work_plan_domain, work_plan: create(:work_plan, user:, student:, grade:), domain: numeration, level: 2)
      WorkPlanSkill.create!(skill: prevue, work_plan_domain: wpd, kind: "ceinture", status: "new")

      apercu = nil
      expect { apercu = described_class.apercu(student, [numeration, grammaire]) }.not_to change(described_class, :count)
      expect(apercu[numeration]).to eq(en_cours: [[2, 1]], resultats: [2, 2])
      expect(apercu[grammaire]).to eq(en_cours: [], resultats: nil)
    end
  end

  describe "l'exercice de ceinture d'une ligne" do
    let!(:skill) { competence(numeration, 1, "Compter") }

    it "prend le premier exercice de ceinture, jamais un exercice classique" do
      create(:challenge, skill:, user:)
      second = create(:challenge, skill:, user:, for_belt: true)
      premier = create(:challenge, skill:, user:, for_belt: true)
      premier.move_to_top

      bloc = described_class.prepare!(student, user).belt_sheet_domains.sole

      expect(bloc.belt_sheet_skills.sole.challenge).to eq(premier)
      expect(second.reload.position).to be > premier.reload.position
    end

    it "saute ceux que l'élève a déjà eus sur une fiche précédente, puis n'en donne plus" do
      premier = create(:challenge, skill:, user:, for_belt: true)
      suivant = create(:challenge, skill:, user:, for_belt: true)

      expect(described_class.prepare!(student, user).belt_sheet_skills.sole.challenge).to eq(premier)
      expect(described_class.prepare!(student, user).belt_sheet_skills.sole.challenge).to eq(suivant)
      expect(described_class.prepare!(student, user).belt_sheet_skills.sole.challenge).to be_nil
    end

    it "signale une compétence déjà validée, par son résultat ou par la ceinture entière" do
      line = described_class.prepare!(student, user).belt_sheet_skills.find_by!(skill:)
      expect(line.deja_validee?).to be(false)

      create(:belt, student:, domain: numeration, level: 1, completed: true)
      expect(BeltSheetSkill.find(line.id).deja_validee?).to be(true)
    end
  end

  describe ".generer!, une fiche d'aucun élève" do
    it "prend toutes les compétences de la ceinture, et le premier exercice de chacune" do
      comparer = competence(numeration, 3, "Comparer")
      ranger = competence(numeration, 3, "Ranger")
      competence(numeration, 4, "Plus tard")
      second = create(:challenge, skill: comparer, user:, for_belt: true)
      premier = create(:challenge, skill: comparer, user:, for_belt: true)
      premier.move_to_top
      # Un résultat d'élève ne compte pas : la fiche n'est celle de personne.
      Result.create!(student:, skill: ranger, kind: "ceinture", status: "completed")

      sheet = described_class.generer!(grade, numeration, 3, user)

      expect(sheet).to have_attributes(student: nil, grade:, user:, non_assignee?: true)
      bloc = sheet.belt_sheet_domains.sole
      expect([bloc.domain, bloc.level]).to eq([numeration, 3])
      expect(bloc.belt_sheet_skills.map { |l| [l.skill, l.challenge] }).to eq([[comparer, premier], [ranger, nil]])
      expect(bloc.belt_sheet_skills.map(&:deja_validee?)).to eq([false, false])
      expect(second.reload.position).to be > premier.reload.position
    end

    it "redonne le même premier exercice d'une fiche à l'autre : aucun élève ne l'a déjà eu" do
      skill = competence(numeration, 1, "Compter")
      premier = create(:challenge, skill:, user:, for_belt: true)
      create(:challenge, skill:, user:, for_belt: true)

      2.times do
        expect(described_class.generer!(grade, numeration, 1, user).belt_sheet_skills.sole.challenge).to eq(premier)
      end
    end

    it "laisse vide le bloc d'un domaine spécial : c'est au professeur de construire sa fiche" do
      geometrie = create(:domain, grade:, name: "Géométrie", position: 3, special: true)
      competence(geometrie, 1, "Tracer")

      bloc = described_class.generer!(grade, geometrie, 1, user).belt_sheet_domains.sole

      expect(bloc.level).to eq(1)
      expect(bloc.belt_sheet_skills).to be_empty
    end

    it "porte son niveau, et se nomme d'après ses blocs" do
      competence(numeration, 2, "Comparer")
      competence(grammaire, 1, "Le verbe")
      sheet = described_class.generer!(grade, numeration, 2, user)
      sheet.add_domain!(grammaire, 1)

      expect(sheet.reload.grade).to eq(grade)
      expect(sheet.nom).to eq("Grammaire blanche · Numération jaune")
      expect(sheet.title).to start_with("Ceintures - CE1 - ")
      sheet.update!(name: "Révisions")
      expect([sheet.nom, sheet.title]).to all(start_with("Révisions"))
      expect(described_class.new(user:)).not_to be_valid
    end
  end

  describe "#clone_for!" do
    let(:camarade) { create(:student, classroom:) }

    it "copie les blocs, les compétences et les exercices pour un autre élève" do
      skill = competence(numeration, 1, "Compter")
      epreuve = create(:challenge, skill:, user:, for_belt: true)
      source = described_class.prepare!(student, user)

      copie = source.clone_for!(camarade, user)

      expect(copie.student).to eq(camarade)
      expect(copie.belt_sheet_skills.map { |l| [l.skill, l.challenge] }).to eq([[skill, epreuve]])
      expect(source.reload.belt_sheet_skills.count).to eq(1)
    end

    it "garde une compétence que l'élève d'arrivée a déjà validée, marquée comme telle" do
      skill = competence(numeration, 1, "Compter")
      Result.create!(student: camarade, skill:, kind: "ceinture", status: "completed")
      source = described_class.prepare!(student, user)

      ligne = source.clone_for!(camarade, user).belt_sheet_skills.sole

      expect(ligne.deja_validee?).to be(true)
    end
  end
end
