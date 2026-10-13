# frozen_string_literal: true

require "rails_helper"

# Annonce du tableau de bord : dans la fenêtre du guide « Bien commencer »,
# fermée pour cette fois (« Plus tard ») ou pour de bon (« Ne plus afficher »).
RSpec.describe "Annonces du tableau de bord", type: :request do
  let(:annonce) { Annonce::ACTIVES.first }
  let(:prof) { create(:user, admin: false, discovery_method: "Bouche-à-oreille") }

  # Un compte déjà installé : ni le guide, ni la question de découverte.
  def compte_installe!
    classe = create(:classroom, user: prof)
    create(:student, classroom: classe)
    create(:work_plan, user: prof)
  end

  it "s'affiche sur le tableau de bord d'un compte installé" do
    compte_installe!
    sign_in prof

    get dashboard_path

    expect(response.body).to include(ERB::Util.html_escape(annonce.titre)).and include("Ne plus afficher").and include("Plus tard")
  end

  it "ne s'affiche plus une fois écartée, et le choix est retenu sur le compte" do
    compte_installe!
    sign_in prof

    patch masquer_annonce_path(annonce.id)

    expect(response).to redirect_to(dashboard_path)
    expect(prof.reload.annonces_masquees).to eq([annonce.id])
    get dashboard_path
    expect(response.body).not_to include(ERB::Util.html_escape(annonce.titre))
  end

  it "laisse la place au guide « Bien commencer » pour un compte sans classe" do
    sign_in prof

    get dashboard_path

    expect(response.body).to include("Bien commencer avec Ensemble")
    expect(response.body).not_to include(ERB::Util.html_escape(annonce.titre))
  end

  it "répond 404 à une annonce inconnue, sans rien écrire" do
    sign_in prof

    patch masquer_annonce_path("inconnue")

    expect(response).to have_http_status(:not_found)
    expect(prof.reload.annonces_masquees).to be_empty
  end
end
