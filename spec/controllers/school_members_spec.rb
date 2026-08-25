# frozen_string_literal: true

require "rails_helper"

# Un invité figure dans la liste des membres sans avoir ni prénom ni nom :
# `teacher.first_name.capitalize` levait un NoMethodError et la page École
# devenait inaccessible au responsable dès sa première invitation.
RSpec.describe SchoolsController, type: :controller do
  render_views

  let(:school) { create(:school, name: "École du Centre") }
  let(:responsable) { create(:user, admin: false, demo: false, first_name: "Claire") }

  before do
    school.add_teacher(responsable, true)
    responsable.reload
    @invited = school.invite_teacher("collegue@ecole.fr", responsable)
    sign_in(responsable)
  end

  describe "#show avec une invitation en attente" do
    it "s'affiche au lieu de planter" do
      expect { get :show, params: { id: school.id } }.not_to raise_error
      expect(response).to be_successful
    end

    it "signale l'invitation, avec l'adresse en clair" do
      get :show, params: { id: school.id }
      expect(response.body).to include("Invitation en attente")
      expect(response.body).to include("collegue@ecole.fr")
    end

    it "affiche normalement les membres qui ont accepté" do
      get :show, params: { id: school.id }
      expect(response.body).to include("Claire")
    end
  end

  describe "listes de collègues" do
    it "écarte l'invité tant qu'il n'a pas accepté" do
      expect(responsable.reload.collegues.map(&:email)).not_to include("collegue@ecole.fr")
      expect(responsable.collegues_with_avatars.map(&:email)).not_to include("collegue@ecole.fr")
    end

    # Le vrai chemin : `accept_invitation!` seul échouerait aux validations,
    # le compte n'ayant encore ni prénom ni nom.
    it "le fait apparaître une fois l'invitation acceptée" do
      User.accept_invitation!(invitation_token: @invited.raw_invitation_token,
                              first_name: "Léa", last_name: "Martin",
                              password: "motdepasse1", password_confirmation: "motdepasse1")

      expect(responsable.reload.collegues.map(&:email)).to include("collegue@ecole.fr")
    end
  end

  describe "User#display_name" do
    it "compose le nom sans les espaces de saisie" do
      user = build(:user, first_name: " léa ", last_name: "martin")
      expect(user.display_name).to eq("Léa Martin")
    end

    it "se rabat sur l'email quand l'identité manque encore" do
      invited = User.find_by(email: "collegue@ecole.fr")
      expect(invited.display_name).to eq("collegue@ecole.fr")
    end
  end
end
