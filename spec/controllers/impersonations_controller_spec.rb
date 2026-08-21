# frozen_string_literal: true

require "rails_helper"

RSpec.describe ImpersonationsController, type: :controller do
  render_views

  let(:admin) { create(:user, admin: true) }
  let(:teacher) { create(:user, admin: false, first_name: "Zoé", last_name: "Martin") }

  describe "#index" do
    it "refuse un utilisateur non connecté" do
      get :index
      expect(response).not_to be_successful
    end

    it "refuse un enseignant" do
      sign_in(teacher)
      get :index
      expect(response).to redirect_to(dashboard_path)
    end

    it "liste les comptes groupés par école, sans les admins" do
      sign_in(admin)
      teacher
      get :index
      expect(response).to be_successful
      expect(response.body).to include("Zoé", teacher.school.name.capitalize)
      # L'email de l'admin apparaît ailleurs dans la page (messagerie du gabarit) :
      # c'est la liste elle-même qu'on interroge.
      listed = Nokogiri::HTML(response.body).css(".impersonation-user-email").map { |node| node.text.strip }
      expect(listed).to include(teacher.email)
      expect(listed).not_to include(admin.email)
    end

    it "range les comptes sans école dans un groupe à part" do
      sign_in(admin)
      teacher.school_role.destroy
      get :index
      expect(response.body).to include("Sans école")
    end
  end

  describe "#create" do
    it "bascule current_user sans déconnecter l'admin" do
      sign_in(admin)
      post :create, params: { user_id: teacher.id }
      expect(response).to redirect_to(dashboard_path)
      expect(session[:impersonated_user_id]).to eq(teacher.id)
      expect(controller.current_user).to eq(teacher)
      expect(controller.true_user).to eq(admin)
    end

    it "refuse de personnifier un autre admin" do
      other_admin = create(:user, admin: true)
      sign_in(admin)
      post :create, params: { user_id: other_admin.id }
      expect(session[:impersonated_user_id]).to be_nil
    end

    it "refuse de se personnifier soi-même" do
      sign_in(admin)
      post :create, params: { user_id: admin.id }
      expect(session[:impersonated_user_id]).to be_nil
    end

    it "refuse un enseignant" do
      sign_in(teacher)
      post :create, params: { user_id: create(:user, admin: false).id }
      expect(session[:impersonated_user_id]).to be_nil
    end

    # Sans le `pundit_user` du contrôleur, la policy interrogerait l'enseignant
    # incarné : l'admin serait prisonnier de la première personnification.
    it "permet de basculer directement vers un autre compte" do
      other_teacher = create(:user, admin: false)
      sign_in(admin)
      session[:impersonated_user_id] = teacher.id
      post :create, params: { user_id: other_teacher.id }
      expect(session[:impersonated_user_id]).to eq(other_teacher.id)
    end
  end

  describe "#destroy" do
    it "rend son compte à l'admin" do
      sign_in(admin)
      session[:impersonated_user_id] = teacher.id
      delete :destroy
      expect(response).to redirect_to(impersonations_path)
      expect(session[:impersonated_user_id]).to be_nil
      expect(controller.current_user).to eq(admin)
    end
  end

  describe "rappel dans la barre de navigation" do
    it "affiche l'identité incarnée et la sortie de secours" do
      sign_in(admin)
      session[:impersonated_user_id] = teacher.id
      get :index
      page = Nokogiri::HTML(response.body)
      expect(page.css(".impersonation-flag").text).to include("Zoé Martin")
      expect(page.css(".impersonation-flag-exit").text).to include("Revenir à mon compte")
      expect(page.css(".impersonation-dropdown-exit").text).to include(admin.first_name)
    end

    it "propose l'accès à la liste quand l'admin est sur son compte" do
      sign_in(admin)
      get :index
      page = Nokogiri::HTML(response.body)
      expect(page.css(".impersonation-flag")).to be_empty
      expect(response.body).to include("Personnifier un utilisateur")
    end
  end

  describe "traçage de l'activité" do
    it "n'inscrit pas de fausse activité sur le compte incarné" do
      teacher.update_column(:last_seen, nil)
      sign_in(admin)
      session[:impersonated_user_id] = teacher.id
      get :index
      expect(teacher.reload.last_seen).to be_nil
    end
  end
end

RSpec.describe SubscriptionsController, type: :controller do
  render_views

  let(:admin) { create(:user, admin: true) }
  let(:teacher) { create(:user, admin: false) }

  describe "garde-fous pendant une personnification" do
    it "ferme la souscription d'un abonnement" do
      sign_in(admin)
      session[:impersonated_user_id] = teacher.id
      get :new
      expect(response).to redirect_to(dashboard_path)
      expect(flash[:alert]).to match(/personnification/i)
    end

    it "laisse passer l'admin sur son propre compte" do
      sign_in(admin)
      get :new
      expect(response).to be_successful
    end
  end
end

RSpec.describe DashboardController, type: :controller do
  render_views

  let(:admin) { create(:user, admin: true) }
  let(:teacher) { create(:user, admin: false, first_name: "Zoé", last_name: "Martin") }

  it "affiche le tableau de bord de l'enseignant incarné, rappel compris" do
    sign_in(admin)
    session[:impersonated_user_id] = teacher.id
    get :show
    expect(response).to be_successful
    expect(Nokogiri::HTML(response.body).css(".impersonation-flag").text).to include("Zoé Martin")
  end
end

RSpec.describe RegistrationsController, type: :controller do
  let(:admin) { create(:user, admin: true) }
  let(:teacher) { create(:user, admin: false) }

  before { @request.env["devise.mapping"] = Devise.mappings[:user] }

  it "interdit l'édition du compte incarné" do
    sign_in(admin)
    session[:impersonated_user_id] = teacher.id
    get :edit
    expect(response).to redirect_to(dashboard_path)
    expect(flash[:alert]).to match(/personnification/i)
  end

  it "laisse l'admin éditer son propre compte" do
    sign_in(admin)
    get :edit
    expect(response).to be_successful
  end
end
