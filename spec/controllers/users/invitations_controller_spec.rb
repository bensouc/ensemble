# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::InvitationsController, type: :controller do
  before { @request.env["devise.mapping"] = Devise.mappings[:user] }

  let(:school) { create(:school, name: "École du Centre") }
  let(:responsable) { create(:user, admin: false, demo: false, first_name: "Claire") }
  let(:membre) { create(:user, admin: false, demo: false) }

  before do
    school.add_teacher(responsable, true)
    school.add_teacher(membre)
    [responsable, membre].each(&:reload)
  end

  def invite(email)
    post :create, params: { user: { email: } }
  end

  describe "envoi de l'invitation" do
    before { sign_in(responsable) }

    it "crée le compte déjà rattaché à l'école, sans mot de passe choisi pour lui" do
      expect { invite("collegue@ecole.fr") }.to change(User, :count).by(1)

      invited = User.find_by(email: "collegue@ecole.fr")
      expect(invited.school).to eq(school)
      expect(invited.demo).to be false
      expect(invited.invited_by).to eq(responsable)
      expect(invited).not_to be_invitation_accepted
    end

    # devise_invitable pose un mot de passe aléatoire pour que l'enregistrement
    # reste valide, mais neutralise `valid_password?` tant que l'invitation n'est
    # pas acceptée : le compte n'ouvre sur rien avant que l'invité passe par le lien.
    it "ne laisse aucun mot de passe ouvrir le compte avant acceptation" do
      invite("collegue@ecole.fr")
      invited = User.find_by(email: "collegue@ecole.fr")
      expect(invited.valid_password?("aA1!nimportequoi")).to be_falsey
    end

    # C'est tout l'objet du changement : avant, le responsable saisissait le mot
    # de passe de son collègue et le lui envoyait en clair.
    it "ne laisse pas le responsable choisir le mot de passe de son collègue" do
      post :create, params: { user: { email: "collegue@ecole.fr", password: "impose1234" } }
      invited = User.find_by(email: "collegue@ecole.fr")
      expect(invited.valid_password?("impose1234")).to be_falsey
    end

    it "n'empile pas de rôle vers l'école de démonstration" do
      invite("collegue@ecole.fr")
      invited = User.find_by(email: "collegue@ecole.fr")
      expect(SchoolRole.where(user: invited).count).to eq(1)
    end

    it "envoie le mail et redirige vers la page du groupe" do
      expect { invite("collegue@ecole.fr") }.to change { ActionMailer::Base.deliveries.count }.by(1)
      expect(response).to redirect_to(school_path(school))
      expect(flash[:notice]).to include("collegue@ecole.fr")
    end

    it "refuse une adresse déjà rattachée à un compte actif" do
      expect { invite(membre.email) }.not_to change(User, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "qui a le droit d'inviter" do
    it "refuse un membre qui n'est pas responsable" do
      sign_in(membre)
      expect { invite("collegue@ecole.fr") }.not_to change(User, :count)
    end

    it "refuse un visiteur non connecté" do
      expect { invite("collegue@ecole.fr") }.not_to change(User, :count)
    end
  end

  describe "acceptation" do
    let(:token) { school.invite_teacher("collegue@ecole.fr", responsable).raw_invitation_token }

    def accept(params)
      put :update, params: { user: { invitation_token: token }.merge(params) }
    end

    def invited = User.find_by(email: "collegue@ecole.fr")

    it "s'ouvre sans être connecté" do
      get :edit, params: { invitation_token: token }
      expect(response).to be_successful
    end

    it "crée le compte avec son identité et son mot de passe" do
      accept(first_name: "Léa", last_name: "Martin", password: "motdepasse1", password_confirmation: "motdepasse1")

      expect(invited).to be_invitation_accepted
      expect(invited.first_name).to eq("Léa")
      expect(invited.school).to eq(school)
      expect(invited.valid_password?("motdepasse1")).to be true
    end

    it "refuse un jeton inconnu" do
      token # l'invitation existe, c'est le jeton présenté qui ne correspond pas
      put :update, params: { user: { invitation_token: "faux", first_name: "Léa", last_name: "Martin",
                                     password: "motdepasse1", password_confirmation: "motdepasse1" } }
      expect(invited).not_to be_invitation_accepted
    end

    # `config.invite_for = 15.days`
    it "refuse un jeton passé de quinze jours" do
      token
      invited.update_column(:invitation_created_at, 16.days.ago)
      accept(first_name: "Léa", last_name: "Martin", password: "motdepasse1", password_confirmation: "motdepasse1")
      expect(invited).not_to be_invitation_accepted
    end

    it "accepte encore au quatorzième jour" do
      token
      invited.update_column(:invitation_created_at, 14.days.ago)
      accept(first_name: "Léa", last_name: "Martin", password: "motdepasse1", password_confirmation: "motdepasse1")
      expect(invited).to be_invitation_accepted
    end
  end
end
