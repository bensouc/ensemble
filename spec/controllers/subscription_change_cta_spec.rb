# frozen_string_literal: true

require "rails_helper"

# Le portail Stripe s'ouvre bien pour une école sur facture, mais n'y propose
# aucune modification — seulement la résiliation. Lui envoyer le responsable sous
# un libellé « ajouter une classe » était le contraire du service rendu.
RSpec.describe "CTA de modification d'abonnement" do
  def abonner(school, collection_method:, quantity: 1)
    Subscription.create!(school:, collection_method:, quantity:, status: "active", rythm: "Annuel",
                         current_period_start: Date.new(2026, 9, 1),
                         current_period_end: Date.new(2027, 8, 31))
  end

  describe SchoolsController, type: :controller do
    render_views

    let(:school) { create(:school, stripe_customer_id: "cus_test") }
    let(:responsable) { create(:user, admin: false, demo: false) }

    def liens
      sign_in(responsable.reload)
      get :show, params: { id: school.id }
      Nokogiri::HTML(response.body).css("a[href='/subscriptions/change_request']")
    end

    before { school.add_teacher(responsable, true) }

    # Sans ce lien, une école sur facture n'a aucune porte pour ajuster sa
    # quantité tant qu'elle n'est pas bloquée en création — et aucune du tout pour
    # la RÉDUIRE, le blocage n'arrivant jamais dans ce sens.
    it "propose la demande sur un abonnement facturé" do
      abonner(school, collection_method: "send_invoice")
      expect(liens.text).to include("modifier le nombre de classes")
    end

    it "ne la propose pas quand le portail Stripe sait le faire" do
      abonner(school, collection_method: "charge_automatically")
      expect(liens).to be_empty
    end

    # Les lignes antérieures à la colonne gardent le comportement d'avant.
    it "ne la propose pas sur une ligne sans mode connu" do
      abonner(school, collection_method: nil)
      expect(liens).to be_empty
    end
  end

  describe ClassroomsController, type: :controller do
    render_views

    let(:school) { create(:school, stripe_customer_id: "cus_test") }
    let(:responsable) { create(:user, admin: false, demo: false) }
    let(:collegue) { create(:user, admin: false, demo: false) }

    def zone
      sign_in(responsable.reload)
      get :index
      Nokogiri::HTML(response.body).css(".classroom-creation")
    end

    before do
      school.add_teacher(responsable, true)
      school.add_teacher(collegue)
      # Deux classes pour une payée : dépassement de quota, la création est fermée
      # et le gabarit propose d'ajouter la classe à l'abonnement.
      2.times { create(:classroom, user: collegue) }
    end

    it "remplace le bouton du portail par la demande, sur un abonnement facturé" do
      abonner(school, collection_method: "send_invoice")
      html = zone

      expect(html.css("a[href='/subscriptions/change_request']")).to be_present
      expect(html.css("form[action='/create-customer-portal-session']")).to be_empty
    end

    it "garde le portail quand il sait modifier l'abonnement" do
      abonner(school, collection_method: "charge_automatically")
      html = zone

      expect(html.css("form[action='/create-customer-portal-session']")).to be_present
      expect(html.css("a[href='/subscriptions/change_request']")).to be_empty
    end
  end
end
