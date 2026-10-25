# frozen_string_literal: true

require "rails_helper"

# La page « Mon compte ». Devise exigeait le mot de passe actuel pour tout, jusqu'à
# la photo : le prénom, le nom et la photo se changent désormais sans lui, l'e-mail
# et le mot de passe restent derrière.
RSpec.describe "Mon compte", type: :request do
  let(:prof) { create(:user, admin: false, first_name: "Camille", last_name: "Martin") }
  let(:png) do
    fichier(Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=="),
            "image/png", "photo.png")
  end

  def fichier(contenu, type, nom)
    Rack::Test::UploadedFile.new(StringIO.new(contenu), type, original_filename: nom)
  end

  def page
    Nokogiri::HTML(response.body)
  end

  def titres_des_blocs
    page.css(".compte-carte h2").map(&:text)
  end

  describe "la page" do
    before { sign_in prof }

    it "montre le profil, la connexion et la suppression du compte, avec les initiales faute de photo" do
      get edit_profile_path

      expect(response).to have_http_status(:ok)
      expect(titres_des_blocs).to eq(["Profil", "Connexion", "Supprimer mon compte"])
      expect(page.at_css(".compte-photo .ui-avatar").text).to eq("CM")
      expect(page.at_css("label[for='fichier-photo']").text.squish).to eq("Ajouter une photo")
      expect(page.at_css("form[action='#{profile_avatar_path}'] input[type=submit]")).to be_nil
    end

    it "ramène au tableau de bord" do
      get edit_profile_path

      lien = page.css("a").find { |a| a.text.squish == "Retour au tableau de bord" }
      expect(lien&.[]("href")).to eq(dashboard_path)
    end

    it "remplace l'écran d'édition de Devise" do
      get edit_user_registration_path

      expect(response).to redirect_to(edit_profile_path)
    end
  end

  it "demande de se connecter" do
    get edit_profile_path

    expect(response).to redirect_to(new_user_session_path)
  end

  describe "le profil, sans mot de passe" do
    before { sign_in prof }

    it "s'enregistre en direct, sans bouton Valider" do
      get edit_profile_path

      expect(page.at_css("#formulaire-profil[data-action~='change->submit-frame#submit']")).to be_present
      expect(page.at_css("#formulaire-profil button")).to be_nil
    end

    it "enregistre le prénom et le nom, et ne redessine que les avatars" do
      patch profile_path, params: { user: { first_name: "Dominique", last_name: "Durand" } }, as: :turbo_stream

      expect(prof.reload).to have_attributes(first_name: "Dominique", last_name: "Durand")
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      cibles = page.css("turbo-stream").map { |flux| [flux["action"], flux["target"]] }
      expect(cibles).to eq([%w[replace compte-avatar], %w[replace avatar-nav], %w[prepend flash]])
      expect(page.css("turbo-stream[target='compte-avatar'] .ui-avatar").text).to eq("DD")
      expect(response.body).to include("Profil enregistré.")
    end

    it "ne touche ni à l'e-mail ni au mot de passe" do
      patch profile_path, params: { user: { first_name: "Camilla", email: "autre@exemple.fr",
                                            password: "autre123", password_confirmation: "autre123" } },
                          as: :turbo_stream

      prof.reload
      expect(prof.first_name).to eq("Camilla")
      expect(prof.email).not_to eq("autre@exemple.fr")
      expect(prof.valid_password?("123456")).to be(true)
    end

    it "refuse un prénom vide, et ne redessine que ce champ, avec son erreur" do
      patch profile_path, params: { user: { first_name: "", last_name: "Martin" } }, as: :turbo_stream

      expect(response).to have_http_status(:unprocessable_content)
      expect(page.css("turbo-stream").map { |flux| flux["target"] }).to eq(["compte-first_name"])
      champ = page.at_css("turbo-stream template #compte-first_name")
      expect(champ.at_css("input#user_first_name[name='user[first_name]'].is-invalid")).to be_present
      expect(champ.at_css(".invalid-feedback").text).to eq("Prénom doit être rempli(e)")
      expect(prof.reload.first_name).to eq("Camille")
    end
  end

  describe "la photo" do
    before { sign_in prof }

    it "s'enregistre dès l'envoi, et remplace les initiales" do
      patch profile_avatar_path, params: { user: { avatar: png } }

      expect(response).to redirect_to(edit_profile_path)
      expect(prof.reload.avatar).to be_attached
      follow_redirect!
      expect(page.at_css(".compte-photo img.ui-avatar--xl")).to be_present
      expect(page.at_css("label[for='fichier-photo']").text.squish).to eq("Changer la photo")
    end

    it "refuse un fichier qui n'est pas une image, même déguisé" do
      patch profile_avatar_path, params: { user: { avatar: fichier("%PDF-1.4\n%%EOF", "image/png", "cv.png") } }

      expect(response).to redirect_to(edit_profile_path)
      expect(flash[:alert]).to eq("La photo doit être une image (JPEG, PNG…)")
      expect(prof.reload.avatar).not_to be_attached
    end

    it "refuse une photo de plus de 5 Mo" do
      lourde = png.read + ("\0" * 5.megabytes)
      patch profile_avatar_path, params: { user: { avatar: fichier(lourde, "image/png", "lourde.png") } }

      expect(flash[:alert]).to eq("La photo ne doit pas dépasser 5 Mo")
      expect(prof.reload.avatar).not_to be_attached
    end

    it "se retire, et les initiales reviennent" do
      prof.avatar.attach(png)

      delete profile_avatar_path

      expect(response).to redirect_to(edit_profile_path)
      expect(prof.reload.avatar).not_to be_attached
    end
  end

  describe "la connexion, derrière le mot de passe actuel" do
    before { sign_in prof }

    it "n'exige que le mot de passe actuel : le nouveau peut rester vide" do
      get edit_profile_path

      exiges = page.css("#formulaire-connexion input[required]").pluck("id")
      expect(exiges).to eq(["user_current_password"])
    end

    it "refuse sans le mot de passe actuel, et réaffiche la page avec l'erreur sans déconnecter" do
      patch user_registration_path, params: { user: { email: "nouveau@exemple.fr", current_password: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(titres_des_blocs).to eq(["Profil", "Connexion", "Supprimer mon compte"])
      expect(page.at_css("#formulaire-connexion #user_current_password.is-invalid")).to be_present
      expect(prof.reload.email).not_to eq("nouveau@exemple.fr")

      get edit_profile_path
      expect(response).to have_http_status(:ok)
    end

    it "change l'e-mail avec le mot de passe actuel, puis revient sur la page" do
      patch user_registration_path, params: { user: { email: "nouveau@exemple.fr", current_password: "123456" } }

      expect(response).to redirect_to(edit_profile_path)
      expect(prof.reload.email).to eq("nouveau@exemple.fr")
    end

    it "n'accepte plus le prénom" do
      patch user_registration_path, params: { user: { first_name: "Autre", current_password: "123456" } }

      expect(prof.reload.first_name).to eq("Camille")
    end
  end

  describe "pendant une personnification" do
    let(:admin) { create(:user, admin: true, school: prof.school) }

    before do
      sign_in admin
      post impersonation_path(prof)
    end

    it "ouvre le profil de la personne, sans sa connexion ni la suppression de son compte" do
      get edit_profile_path

      expect(titres_des_blocs).to eq(["Profil"])
    end

    it "change son prénom" do
      patch profile_path, params: { user: { first_name: "Camilla" } }, as: :turbo_stream

      expect(prof.reload.first_name).to eq("Camilla")
    end

    it "garde ses identifiants fermés" do
      patch user_registration_path, params: { user: { email: "autre@exemple.fr", current_password: "123456" } }

      expect(prof.reload.email).not_to eq("autre@exemple.fr")
    end
  end
end
