# frozen_string_literal: true

# Recrée en test mode le produit et les prix qui existent en live, pour pouvoir
# travailler en développement sans toucher aux données réelles.
#
# Les identifiants de prix sont propres à un mode : un `price_…` live est
# introuvable en test, et le Checkout casse. Cette tâche évite de les ressaisir.
#
#   STRIPE_TEST_API_KEY=sk_test_… bin/rails stripe:clone_to_test
#
# La table tarifaire (STRIPE_SCHOOL_PRICING_ID) n'est PAS clonable : l'API Stripe
# n'expose aucune ressource « pricing table », elle se recrée dans le Dashboard.
namespace :stripe do
  # Des méthodes plutôt que des constantes : un `namespace` est un bloc, et une
  # constante y fuirait dans l'espace de noms global.
  def produit_live = "prod_PjNUr9bvQCInbA"

  # Trace l'objet d'origine, pour que la tâche soit rejouable sans doublon.
  def marqueur = "clone_depuis"

  desc "Clone le produit et les prix Stripe du live vers le test mode"
  task clone_to_test: :environment do
    live = ENV.fetch("STRIPE_API_KEY", nil)
    test = ENV.fetch("STRIPE_TEST_API_KEY", nil)

    abort "STRIPE_API_KEY manquante (clé source)." if live.blank?
    abort "STRIPE_TEST_API_KEY manquante (clé cible)." if test.blank?
    # Sans ce garde-fou, une clé live en cible dupliquerait le produit en production.
    abort "STRIPE_TEST_API_KEY n'est pas une clé de test." unless test.include?("_test_")

    source = lire_source(live)
    puts "Source : #{source[:produit].name.inspect} — #{source[:prix].size} prix actif(s)"

    Stripe.api_key = test
    produit = produit_cible(source[:produit])
    puts "Produit test : #{produit.id}"

    puts "\nÀ reporter dans votre .env de développement :"
    source[:prix].each do |prix_live|
      cree = cloner_prix(prix_live, produit.id)
      variable = prix_live.recurring.interval == "year" ? "STRIPE_PRICE_ANNUALY" : "STRIPE_PRICE_MONTHLY"
      puts "  #{variable}=#{cree.id}"
    end
    puts "\nRestent à faire à la main dans le Dashboard (test mode) :"
    puts "  STRIPE_SCHOOL_PRICING_ID  — l'API ne crée pas de table tarifaire"
    puts "  STRIPE_PUBLISHABLE_KEY    — la clé publiable du test mode"
    puts "  STRIPE_WEBHOOK_SECRET_KEY — celui que donne `stripe listen`"
  end

  # Les paliers ne reviennent que sur demande explicite.
  def lire_source(cle)
    Stripe.api_key = cle
    produit = Stripe::Product.retrieve(produit_live)
    prix = Stripe::Price.list(product: produit.id, active: true, limit: 100).data.map do |p|
      Stripe::Price.retrieve({ id: p.id, expand: ["tiers"] })
    end
    { produit:, prix: }
  end

  # Idempotent : relancer la tâche ne crée pas un second produit.
  def produit_cible(source)
    tous = Stripe::Product.list(active: true, limit: 100).data
    existant = tous.find { |p| p.metadata[marqueur] == source.id }
    return existant if existant

    Stripe::Product.create(name: source.name, description: source.description,
                           unit_label: source.unit_label, tax_code: source.tax_code,
                           metadata: { marqueur => source.id })
  end

  def cloner_prix(source, produit_id)
    tous = Stripe::Price.list(product: produit_id, active: true, limit: 100).data
    existant = tous.find { |p| p.metadata[marqueur] == source.id }
    return existant if existant

    Stripe::Price.create(base_du_prix(source, produit_id).merge(tarification(source)))
  end

  def base_du_prix(source, produit_id)
    { product: produit_id, currency: source.currency, nickname: source.nickname,
      tax_behavior: source.tax_behavior, metadata: { marqueur => source.id },
      recurring: { interval: source.recurring.interval,
                   interval_count: source.recurring.interval_count,
                   usage_type: source.recurring.usage_type } }
  end

  # Les prix d'Ensemble sont à paliers en mode volume ; le cas forfaitaire est là
  # au cas où un prix simple serait ajouté un jour.
  def tarification(source)
    return { unit_amount: source.unit_amount } unless source.billing_scheme == "tiered"

    { billing_scheme: "tiered", tiers_mode: source.tiers_mode,
      tiers: source.tiers.map do |t|
        { up_to: t.up_to || "inf", unit_amount: t.unit_amount, flat_amount: t.flat_amount }.compact
      end }
  end
end
