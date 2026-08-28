# frozen_string_literal: true

require "rails_helper"

# Deux personnes seulement peuvent défaire un partage : celle qui le subit, pour
# quitter la classe, et le propriétaire, pour reprendre la sienne. Le contrôleur
# autorisait la CLASSE et non le partage, si bien que n'importe quel collègue
# passait — et pouvait retirer le partage d'un autre collègue.
RSpec.describe SharedClassroomPolicy do
  let(:school) { create(:school) }
  let(:grade) { create(:grade, school:) }
  let(:owner) { create(:user, admin: false, demo: false) }
  let(:colleague) { create(:user, admin: false, demo: false) }
  let(:other_colleague) { create(:user, admin: false, demo: false) }
  let(:stranger) { create(:user, admin: false, demo: false) }
  let(:classroom) { create(:classroom, user: owner, grade:) }
  let(:share) { create(:shared_classroom, user: colleague, classroom:) }

  describe "#destroy?" do
    it "autorise le collègue concerné, qui quitte la classe" do
      expect(described_class.new(colleague, share).destroy?).to be true
    end

    it "autorise le propriétaire, qui reprend sa classe" do
      expect(described_class.new(owner, share).destroy?).to be true
    end

    it "refuse à un autre collègue de retirer ce partage" do
      create(:shared_classroom, user: other_colleague, classroom:)
      expect(described_class.new(other_colleague, share).destroy?).to be false
    end

    it "refuse un tiers" do
      expect(described_class.new(stranger, share).destroy?).to be false
    end

    it "autorise un admin" do
      expect(described_class.new(create(:user, admin: true), share).destroy?).to be true
    end
  end
end
