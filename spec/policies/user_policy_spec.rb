# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserPolicy do
  let(:prof) { build_stubbed(:user, admin: false) }

  describe "#update?" do
    it "laisse chacun changer son prénom, son nom et sa photo" do
      expect(described_class.new(prof, prof).update?).to be(true)
    end

    it "refuse ceux d'un autre, collègue ou admin" do
      collegue = build_stubbed(:user, admin: false)
      admin = build_stubbed(:user, admin: true)

      expect(described_class.new(prof, collegue).update?).to be(false)
      expect(described_class.new(admin, prof).update?).to be(false)
    end
  end
end
