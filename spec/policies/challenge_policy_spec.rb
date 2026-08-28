# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChallengePolicy do
  # Un exercice survit au départ de son auteur, il n'en a alors plus.
  # `record.user.admin?` levait un NoMethodError dans ce cas. Le rattachement qui
  # compte est `record.skill.school`, jamais l'auteur.
  describe "#destroy? sur un exercice sans auteur" do
    let(:teacher) { create(:user, admin: false, demo: false) }
    let(:challenge) do
      challenge = create(:challenge)
      challenge.update_column(:user_id, nil)
      challenge.reload
    end

    it "ne lève pas" do
      expect { described_class.new(teacher, challenge).destroy? }.not_to raise_error
    end

    it "autorise encore un prof de l'école de la compétence" do
      challenge.skill.update!(school: teacher.school)
      expect(described_class.new(teacher, challenge).destroy?).to be true
    end
  end
  # Déplacer un exercice sous une autre compétence n'est possible que tant
  # qu'aucun plan de travail ne s'y réfère : le changer de compétence après coup
  # réécrirait l'historique d'un élève.
  describe "#transferable?" do
    let(:school) { create(:school) }
    let(:teacher) { create(:user, admin: false, demo: false) }
    let(:skill) { create(:skill, school: teacher.school) }
    let(:challenge) { create(:challenge, user: teacher, skill:) }

    it "autorise un exercice que personne n'utilise" do
      expect(described_class.new(teacher, challenge).transferable?).to be true
    end

    it "refuse dès qu'un plan de travail s'y réfère" do
      create(:work_plan_skill, challenge:, skill:, work_plan_domain: create(:work_plan_domain))

      expect(described_class.new(teacher, challenge.reload).transferable?).to be false
    end

    # Tous les enseignants d'une école travaillent sur ses exercices : ce n'est
    # pas réservé à celui qui l'a écrit.
    it "autorise un collègue de l'école, pas seulement l'auteur" do
      collegue = create(:user, admin: false, demo: false)
      school.add_teacher(collegue)
      collegue.reload
      chez_le_collegue = create(:challenge, user: teacher, skill: create(:skill, school: collegue.school))

      expect(described_class.new(collegue, chez_le_collegue).transferable?).to be true
    end

    it "refuse l'exercice d'une autre école" do
      etranger = create(:user, admin: false, demo: false)

      expect(described_class.new(etranger, challenge).transferable?).to be false
    end
  end
end
