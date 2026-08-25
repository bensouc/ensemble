# frozen_string_literal: true

require "rails_helper"

# La table tarifaire recevait ENV["STRIPE_API_KEY"] comme `publishable-key` : la clé
# SECRÈTE — celle que StripeHelper pose comme `Stripe.api_key` — partait en clair dans le
# HTML. La page est ouverte à tout utilisateur connecté (SubscriptionPolicy#school_pricing?
# renvoie `true`), donc n'importe qui pouvait la lire dans le source.
RSpec.describe SubscriptionsController, type: :controller do
  render_views

  let(:school) { create(:school, stripe_customer_id: "cus_test") }
  let(:teacher) { create(:user, admin: false, demo: false) }

  # `school_pricing` interroge l'API Stripe pour retrouver le client : on la neutralise,
  # un test ne doit pas sortir sur le réseau.
  let(:customer) { Stripe::Customer.construct_from(id: "cus_test", email: "ecole@exemple.fr") }

  before do
    school.add_teacher(teacher, true)
    allow(StripeHelper).to receive(:get_or_create_customer).and_return(customer)

    # Valeurs reconnaissables plutôt que celles de l'environnement : sans ça, le test
    # passerait quelle que soit la vue.
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:[]).with("STRIPE_API_KEY").and_return("sk_test_SECRET_A_NE_PAS_SERVIR")
    allow(ENV).to receive(:fetch).with("STRIPE_API_KEY", nil).and_return("sk_test_SECRET_A_NE_PAS_SERVIR")
    allow(ENV).to receive(:fetch).with("STRIPE_PUBLISHABLE_KEY", nil).and_return("pk_test_publique")
    allow(ENV).to receive(:fetch).with("STRIPE_SCHOOL_PRICING_ID", nil).and_return("prctbl_test")

    sign_in(teacher.reload)
    get :school_pricing
  end

  describe "#school_pricing" do
    it "ne sert jamais la clé secrète dans le HTML" do
      expect(response.body).not_to include("sk_test_SECRET_A_NE_PAS_SERVIR")
      expect(response.body).not_to match(/sk_(test|live)_/)
    end

    it "sert la clé publiable à la table tarifaire" do
      table = Nokogiri::HTML(response.body).css("stripe-pricing-table").first
      expect(table).to be_present
      expect(table["publishable-key"]).to eq("pk_test_publique")
    end

    # Les attributs étaient écrits `publishable-key= <%= … %>`, sans guillemets.
    it "quote ses attributs" do
      expect(response.body).not_to match(/publishable-key=\s+\S/)
    end
  end
end

# Garde-fou plus large que la seule table tarifaire : rien de servi au navigateur ne doit
# lire une variable d'environnement secrète. C'est un test de dépôt, pas de comportement —
# il attrape la prochaine occurrence où qu'elle apparaisse.
RSpec.describe "Secrets côté client" do
  let(:secrets) do
    %w[STRIPE_API_KEY STRIPE_WEBHOOK_SECRET_KEY RECAPTCHA_SECRET_KEY
       GANDI_MAIL_PSWORD CHALLENGE_MISTRAL_API_KEY]
  end

  it "n'apparaissent dans aucun gabarit ni script servi au navigateur" do
    # Restreint aux fichiers texte : `app/assets` est surtout des images, des
    # polices et des bundles générés — 21 Mo de binaire relus à chaque passage,
    # pour zéro couverture supplémentaire.
    fichiers = Rails.root.glob("app/{views,javascript}/**/*.{erb,html,js,jsx,ts,vue,json}") +
               Rails.root.glob("app/assets/stylesheets/**/*.{scss,css}")
    fautifs = fichiers.filter_map do |f|
      contenu = File.read(f, encoding: "UTF-8", invalid: :replace)
      trouves = secrets.select { |cle| contenu.include?(cle) }
      "#{Pathname.new(f).relative_path_from(Rails.root)} → #{trouves.join(', ')}" if trouves.any?
    end

    expect(fautifs).to be_empty, "Variables secrètes servies au client :\n  #{fautifs.join("\n  ")}"
  end
end
