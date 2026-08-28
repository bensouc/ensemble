# frozen_string_literal: true

require "rails_helper"

# L'application a quitté Scalingo pour un serveur OVHcloud. Deux pages
# l'annonçaient encore — dont les mentions légales, où nommer le véritable
# hébergeur est une obligation.
RSpec.describe "L'hébergement annoncé", type: :request do
  it "nomme OVHcloud dans les mentions légales" do
    get mentions_legales_path

    expect(response.body).to include("OVHcloud")
  end

  it "ne mentionne plus l'ancien hébergeur ni son sous-traitant" do
    get mentions_legales_path

    expect(response.body).not_to include("Scalingo", "SCALINGO", "OUTSCALE")
  end

  # La gamme VPS d'OVHcloud est hors du périmètre certifié ISO 27001 : la
  # mention héritée de Scalingo ne peut pas être reportée. Cette spec est le
  # garde-fou — on ne la remet pas par inadvertance.
  it "ne revendique pas une certification de sécurité qu'on n'a pas" do
    get mentions_legales_path

    expect(response.body).not_to include("27001")
  end

  it "nomme la certification qualité pour ce qu'elle est" do
    get mentions_legales_path

    expect(response.body).to include("ISO 9001", "management de la qualité")
  end

  it "l'annonce aussi sur la page d'accueil" do
    get root_path

    expect(response.body).to include("OVHcloud")
    expect(response.body).not_to include("Scalingo")
  end
end

RSpec.describe "L'accueil mobile", type: :request do
  # `pages#home` choisit son contenu sur le user-agent (gem `mobile`) : sans
  # cet en-tête, c'est la page de bureau qui se rend.
  let(:telephone) do
    { "HTTP_USER_AGENT" => "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) " \
                           "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1" }
  end

  # Le bouton annonçait « S'incrire » et menait à la liste des plans de travail.
  # L'apostrophe sort échappée en HTML : on cherche la racine du mot, pas la
  # chaîne telle qu'écrite dans le gabarit — sans quoi le test passe au vert
  # sans rien prouver.
  it "propose de s'inscrire à un visiteur, vers la vraie page d'inscription" do
    get root_path, headers: telephone

    expect(response.body).to include("inscrire")
    expect(response.body).to include(new_user_registration_path)
    expect(response.body).not_to include("incrire")
  end

  context "quand l'enseignant est déjà connecté" do
    let(:teacher) { create(:user, admin: false, demo: false) }

    before { sign_in teacher }

    it "ne lui propose pas de s'inscrire" do
      get root_path, headers: telephone

      expect(response.body).not_to include("inscrire")
      expect(response.body).to include("Voir mes plans de travail")
    end
  end

  it "dit que le mobile fonctionne sans réseau" do
    get root_path, headers: telephone

    expect(response.body).to include("même sans réseau")
  end
end
