# frozen_string_literal: true

require "rails_helper"

RSpec.describe NavigationMobileHelper, type: :helper do
  def sur(chemin)
    allow(helper.request).to receive(:path).and_return(chemin)
  end

  describe "#onglet_mobile_actif?" do
    # `current_page?` ne convient pas : il exige l'URL exacte, et l'onglet
    # s'éteignait dès qu'on ouvrait une fiche élève.
    it "reste allumé sur les pages filles" do
      sur("/mobile/classrooms/12/students/7")

      expect(helper.onglet_mobile_actif?("/mobile/classrooms")).to be true
    end

    it "s'éteint sur une autre section" do
      sur("/mobile/work_plans")

      expect(helper.onglet_mobile_actif?("/mobile/classrooms")).to be false
    end

    # La racine est le seul chemin dont tout est préfixe : sans exception, elle
    # resterait allumée partout.
    it "n'allume l'accueil que sur l'accueil" do
      sur("/mobile/classrooms")

      expect(helper.onglet_mobile_actif?("/")).to be false
    end

    it "allume bien l'accueil sur l'accueil" do
      sur("/")

      expect(helper.onglet_mobile_actif?("/")).to be true
    end
  end

  describe "#classe_onglet_mobile" do
    it "marque l'onglet courant" do
      sur("/mobile/classrooms")

      expect(helper.classe_onglet_mobile("/mobile/classrooms")).to eq("mobile-user-menu --actif")
    end

    it "laisse les autres au repos" do
      sur("/mobile/work_plans")

      expect(helper.classe_onglet_mobile("/mobile/classrooms")).to eq("mobile-user-menu")
    end
  end
end
