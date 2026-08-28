# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mobile::WorkPlansHelper, type: :helper do
  # `pluralize` est sensible à la locale et le français n'a pas d'inflexion
  # définie : « 3 plan » en sortait.
  describe "#plans_label" do
    it "reste au singulier pour un plan" do
      expect(helper.plans_label(1)).to eq("1 plan")
    end

    it "accorde au pluriel au-delà" do
      expect(helper.plans_label(3)).to eq("3 plans")
    end

    it "reste au singulier quand l'élève n'en a aucun" do
      expect(helper.plans_label(0)).to eq("0 plan")
    end
  end
end
