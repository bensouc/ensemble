# frozen_string_literal: true

require "rails_helper"

RSpec.describe Mobile::ClassroomsHelper, type: :helper do
  # `pluralize` est sensible à la locale et aucune inflexion n'est définie pour
  # le français : il renvoyait « 2 élève », sans bruit. Même raison d'être que
  # `ClassroomsHelper#classes_label`.
  describe "#eleves_label" do
    it "reste au singulier pour un élève" do
      expect(helper.eleves_label(1)).to eq("1 élève")
    end

    it "accorde au pluriel au-delà" do
      expect(helper.eleves_label(2)).to eq("2 élèves")
    end

    it "reste au singulier pour une classe vide" do
      expect(helper.eleves_label(0)).to eq("0 élève")
    end
  end
end
