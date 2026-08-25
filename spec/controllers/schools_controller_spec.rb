# frozen_string_literal: true

require "rails_helper"

RSpec.describe SchoolsController, type: :controller do
  render_views

  let(:school) { create(:school) }
  let(:head_teacher) { create(:user, admin: false) }
  let(:member) { create(:user, admin: false) }

  before do
    school.add_teacher(head_teacher, true)
    school.add_teacher(member)
  end

  # La factory :subscription est commentée : le bloc du code ne s'affiche que
  # sous un abonnement, il en faut donc un vrai.
  def subscribe(school)
    Subscription.create!(school:, status: "active", quantity: 3, rythm: "Annuel",
                         current_period_start: Date.new(2026, 9, 1),
                         current_period_end: Date.new(2027, 8, 31))
  end

  describe "#renew_code" do
    it "tire un nouveau code pour le responsable du groupe" do
      sign_in(head_teacher)
      expect { patch :renew_code, params: { id: school.id } }.to(change { school.reload.code })
      expect(response).to redirect_to(school_path(school))
      expect(flash[:notice]).to include(school.reload.code)
    end

    # Renouveler coupe l'accès de tous ceux qui détiennent l'ancien code.
    it "le refuse à un membre qui n'est pas responsable" do
      sign_in(member)
      expect { patch :renew_code, params: { id: school.id } }.not_to(change { school.reload.code })
    end

    it "le refuse à un enseignant d'une autre école" do
      outsider = create(:user, admin: false)
      sign_in(outsider)
      expect { patch :renew_code, params: { id: school.id } }.not_to(change { school.reload.code })
    end
  end

  describe "#show" do
    it "montre le code et le bouton de renouvellement au responsable" do
      subscribe(school)
      sign_in(head_teacher)
      get :show, params: { id: school.id }
      expect(response.body).to include(school.code)
      expect(response.body).to include("Renouveler le code")
    end

    it "montre le code sans le bouton à un simple membre" do
      subscribe(school)
      sign_in(member)
      get :show, params: { id: school.id }
      expect(response.body).to include(school.code)
      expect(response.body).not_to include("Renouveler le code")
    end
  end
end
