# frozen_string_literal: true

require "rails_helper"

# Annonce du tableau de bord : dans la fenêtre du guide « Bien commencer »,
# fermée pour cette fois (« Plus tard ») ou pour de bon (« Ne plus afficher »).
RSpec.describe "Annonces du tableau de bord", type: :request do
  include ActiveSupport::Testing::TimeHelpers

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

  # Plus haute que l'écran, la fenêtre cachait ses boutons sous le pli : rien ne
  # disait qu'il fallait descendre pour l'écarter.
  it "prévoit l'indice « Suite plus bas », caché tant que tout tient à l'écran" do
    compte_installe!
    sign_in prof

    get dashboard_path

    page = Nokogiri::HTML(response.body)
    expect(page.at_css(".annonce__contenu")["data-controller"]).to eq("suite-plus-bas")
    indice = page.at_css(".annonce__contenu .annonce__suite")
    expect(indice["hidden"]).not_to be_nil
    expect(indice.at_css("button")["data-action"]).to eq("suite-plus-bas#descendre")
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

  it "« Plus tard » la remet au lendemain" do
    compte_installe!
    sign_in prof

    patch reporter_annonce_path(annonce.id)
    get dashboard_path
    expect(response.body).not_to include(ERB::Util.html_escape(annonce.titre))

    travel 1.day do
      get dashboard_path
      expect(response.body).to include(ERB::Util.html_escape(annonce.titre))
    end
  end

  it "ne s'affiche pas pendant une personnification, et n'écrit rien sur le compte" do
    compte_installe!
    admin = create(:user, admin: true, school: prof.school)
    sign_in admin
    post impersonation_path(prof)

    get dashboard_path
    expect(response.body).not_to include(ERB::Util.html_escape(annonce.titre))

    patch masquer_annonce_path(annonce.id)
    expect(prof.reload.annonces_masquees).to be_empty
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
