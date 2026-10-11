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
end
