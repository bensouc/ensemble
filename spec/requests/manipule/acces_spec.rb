# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Manipule, l'ouverture de l'option" do
  # La factory :user fabrique un ADMIN. Un admin passe tous les gardes d'ici,
  # et les tests ne testeraient alors rien du tout.
  let(:enseignante) { create(:user, admin: false) }
  let(:admin) { create(:user, admin: true) }

  describe "le garde posé sur les écrans de l'enseignante" do
    it "renvoie une enseignante dont l'option est fermée" do
      sign_in enseignante

      get manipule_root_path

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include("pas ouvert")
    end

    it "laisse entrer celle dont l'option est ouverte" do
      sign_in create(:user, admin: false, manipule: true)

      get manipule_root_path

      expect(response).to have_http_status(:ok)
    end

    # L'admin ouvre l'option aux autres : il doit pouvoir regarder ce qu'il
    # ouvre, sans se l'ouvrir à lui-même d'abord.
    it "laisse entrer un admin qui n'a pas l'option" do
      sign_in admin

      get manipule_root_path

      expect(response).to have_http_status(:ok)
      expect(admin.reload.manipule).to be(false)
    end

    it "couvre aussi la banque et les classes, pas seulement l'accueil" do
      sign_in enseignante

      [manipule_banque_path, manipule_suivi_path].each do |chemin|
        get chemin
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "l'écran des accès" do
    it "s'ouvre pour un admin" do
      sign_in admin

      get manipule_acces_path

      expect(response).to have_http_status(:ok)
    end

    it "se refuse à une enseignante, même si Manipule lui est ouvert" do
      sign_in create(:user, admin: false, manipule: true)

      get manipule_acces_path

      expect(response).to redirect_to(manipule_root_path)
      expect(flash[:alert]).to include("administrateurs")
    end

    # Sans recherche on ne liste que les comptes déjà ouverts : déverser
    # l'annuaire entier ne rend service à personne.
    it "ne liste que les comptes ouverts tant qu'on ne cherche rien" do
      ouvert = create(:user, admin: false, manipule: true, email: "ouverte@exemple.fr")
      ferme = create(:user, admin: false, email: "fermee@exemple.fr")
      sign_in admin

      get manipule_acces_path

      expect(response.body).to include(ouvert.email)
      expect(response.body).not_to include(ferme.email)
    end

    it "retrouve un compte fermé par une recherche" do
      ferme = create(:user, admin: false, email: "fermee@exemple.fr", last_name: "Lemoine")
      sign_in admin

      get manipule_acces_path, params: { q: "lemoine" }

      expect(response.body).to include(ferme.email)
    end
  end

  describe "l'ouverture et la fermeture" do
    it "ouvre l'option à quelqu'un" do
      sign_in admin

      patch manipule_acces_utilisateur_path(enseignante), params: { manipule: true }

      expect(enseignante.reload.manipule).to be(true)
    end

    it "la referme" do
      cible = create(:user, admin: false, manipule: true)
      sign_in admin

      patch manipule_acces_utilisateur_path(cible), params: { manipule: false }

      expect(cible.reload.manipule).to be(false)
    end

    # Le vrai risque : quelqu'un qui n'est pas admin s'ouvre l'option tout seul
    # en postant directement sur l'adresse.
    it "refuse à une enseignante de se l'ouvrir elle-même" do
      sign_in enseignante

      patch manipule_acces_utilisateur_path(enseignante), params: { manipule: true }

      expect(enseignante.reload.manipule).to be(false)
    end
  end
end
