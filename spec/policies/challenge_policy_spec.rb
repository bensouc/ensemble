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
end
