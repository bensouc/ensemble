# frozen_string_literal: true

# Outils d'exploitation Stripe, en lecture seule sauf mention contraire.
#
# Le corps vit dans un module : les `def` écrits directement dans un bloc
# `namespace` atterrissent en méthodes privées d'`Object` — vérifié, `alerte` et
# `marqueur` devenaient appelables sur n'importe quel objet sous rake.
module StripeTaches
  module_function

  PRODUIT_LIVE = "prod_PjNUr9bvQCInbA"
  MARQUEUR = "clone_depuis"
  MENTION_TVA = "TVA non applicable, art. 293 B du CGI"
  # Le repère de détection dérive de la mention : changer l'une changeait
  # l'écriture sans changer la reconnaissance.
  REPERE_MENTION = "293 B"

  def alerte(condition) = condition ? "  <-- À VÉRIFIER" : ""

  def porte_la_mention?(objet, champ = :footer)
    objet.public_send(champ).to_s.include?(REPERE_MENTION)
  end

  # La clé et le bandeau de mode : c'est ici que se décide si l'on écrit en
  # production, le seul endroit du fichier où une divergence coûterait cher.
  def preparer_cle(role)
    cle = ENV.fetch("STRIPE_AUDIT_API_KEY", nil) || ENV.fetch("STRIPE_API_KEY", nil)
    abort "Aucune clé." if cle.blank?
    Stripe.api_key = cle
    puts "Mode #{cle.include?('_live_') ? 'LIVE' : 'test'} — #{role}\n\n"
    cle
  end

  def tout(liste, &)
    resultats = []
    liste.auto_paging_each { |o| resultats << o if yield(o) }
    resultats
  end

  def abonnements_taxes = tout(Stripe::Subscription.list(limit: 100)) { |s| s.automatic_tax&.enabled }

  # ---------- audit ----------

  def auditer_compte
    puts "Stripe Tax (compte) : statut=#{Stripe::Tax::Settings.retrieve.status}"
    immat = Stripe::Tax::Registration.list(status: "active", limit: 100).data
    puts "Immatriculations fiscales actives : #{immat.size}#{alerte(immat.any?)}"
    immat.each { |r| puts "  #{r.country} #{r.type} depuis #{Time.zone.at(r.active_from).to_date}" }
  rescue Stripe::StripeError => e
    puts "Stripe Tax : non consultable (#{e.class})"
  end

  def auditer_prix
    puts "\nPrix avec un comportement fiscal explicite :"
    fautifs = tout(Stripe::Price.list(active: true, limit: 100)) { |p| p.tax_behavior != "unspecified" }
    puts fautifs.empty? ? "  aucun — tous en `unspecified`" : fautifs.map { |p| "  #{p.id} #{p.tax_behavior}" }
  end

  def auditer_abonnements
    puts "\nAbonnements avec taxe automatique :"
    avec = abonnements_taxes
    puts avec.empty? ? "  aucun" : avec.map { |s| "  #{s.id} (#{s.status})#{alerte(true)}" }
  end

  def auditer_factures(factures)
    puts "\nFactures récentes portant une taxe :"
    avec = factures.filter_map { |f| ligne_de_taxe(f) }
    puts avec.empty? ? "  aucune — 0 € de taxe partout" : avec
  end

  def ligne_de_taxe(facture)
    taxe = facture.total_taxes.to_a.sum { |t| t.respond_to?(:amount) ? t.amount.to_i : 0 }
    return nil unless taxe.positive?

    format("  %<id>-28s total=%<t>8.2f taxe=%<x>6.2f",
           id: facture.id, t: facture.total.to_i / 100.0, x: taxe / 100.0)
  end

  # Le pied de page par défaut du compte n'est pas lisible par l'API — c'est un
  # modèle de document, réglé dans le Dashboard. On le constate donc sur les
  # factures qu'il produit.
  def auditer_mention(factures)
    puts "\nMention de franchise sur les dernières factures :"
    if factures.empty?
      puts "  aucune facture à examiner"
      return
    end
    factures.first(10).each { |f| puts ligne_de_mention(f) }
    puts "  Une facture antérieure au réglage ne la portera jamais : le pied de"
    puts "  page est figé à la finalisation."
  end

  def ligne_de_mention(facture)
    format("  %<id>-28s %<date>s %<etat>s", id: facture.id,
                                            date: Time.zone.at(facture.created).to_date,
                                            etat: porte_la_mention?(facture) ? "mention présente" : "SANS MENTION")
  end

  # ---------- écriture ----------

  def couper_taxe_abonnements(ecrire)
    vises = abonnements_taxes
    puts "Abonnements avec taxe automatique : #{vises.size}"
    vises.each do |s|
      puts "  #{s.id} (#{s.status})#{' -> coupée' if ecrire}"
      Stripe::Subscription.update(s.id, automatic_tax: { enabled: false }) if ecrire
    end
  end

  def poser_mention_brouillons(ecrire)
    vises = tout(Stripe::Invoice.list(status: "draft", limit: 100)) { |f| !porte_la_mention?(f) }
    puts "\nFactures brouillon sans la mention : #{vises.size}"
    vises.each do |f|
      puts "  #{f.id}#{' -> mention posée' if ecrire}"
      Stripe::Invoice.update(f.id, footer: MENTION_TVA) if ecrire
    end
  end

  def poser_mention_clients(ecrire)
    total = 0
    vises = tout(Stripe::Customer.list(limit: 100)) do |c|
      total += 1
      c.invoice_settings.nil? || !porte_la_mention?(c.invoice_settings)
    end
    puts "\nClients sans la mention : #{vises.size} sur #{total}"
    puts "  (une écriture par client — préférez le pied de page du compte)" if vises.size > 50
    vises.each do |c|
      puts "  #{c.id} #{c.email}#{' -> mention posée' if ecrire}"
      Stripe::Customer.update(c.id, invoice_settings: { footer: MENTION_TVA }) if ecrire
    end
  end

  # ---------- clonage ----------

  # `expand: ["data.tiers"]` sur la liste : sans lui, il fallait un aller-retour
  # réseau par prix rien que pour obtenir les paliers.
  def lire_source(cle)
    Stripe.api_key = cle
    produit = begin
      Stripe::Product.retrieve(PRODUIT_LIVE)
    rescue Stripe::AuthenticationError
      abort "STRIPE_API_KEY refusée par Stripe."
    rescue Stripe::InvalidRequestError
      abort "Produit #{PRODUIT_LIVE} introuvable avec STRIPE_API_KEY.\n" \
            "Cette tâche doit tourner AVANT de basculer STRIPE_API_KEY en test : " \
            "c'est cette clé qui lit le produit live."
    end
    { produit:,
      prix: Stripe::Price.list(product: produit.id, active: true, limit: 100, expand: ["data.tiers"]).data }
  end

  # Idempotent : chaque objet cloné porte l'id de sa source en metadata.
  def clone_de(liste, source_id) = liste.find { |o| o.metadata[MARQUEUR] == source_id }

  def produit_cible(source)
    existant = clone_de(Stripe::Product.list(active: true, limit: 100).data, source.id)
    return existant if existant

    Stripe::Product.create(name: source.name, description: source.description,
                           unit_label: source.unit_label, tax_code: source.tax_code,
                           metadata: { MARQUEUR => source.id })
  end

  def cloner_prix(source, produit_id, deja_clones)
    existant = clone_de(deja_clones, source.id)
    return existant if existant

    Stripe::Price.create(base_du_prix(source, produit_id).merge(tarification(source)))
  end

  def base_du_prix(source, produit_id)
    { product: produit_id, currency: source.currency, nickname: source.nickname,
      tax_behavior: source.tax_behavior, metadata: { MARQUEUR => source.id },
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

namespace :stripe do
  desc "Vérifie qu'aucune TVA n'est appliquée (lecture seule)"
  task audit_tva: :environment do
    StripeTaches.preparer_cle("lecture seule")
    factures = Stripe::Invoice.list(limit: 100).data
    StripeTaches.auditer_compte
    StripeTaches.auditer_prix
    StripeTaches.auditer_abonnements
    StripeTaches.auditer_factures(factures)
    StripeTaches.auditer_mention(factures)
  end

  # Franchise en base de TVA : aucune taxe ne doit être calculée, et la mention
  # légale doit figurer sur chaque facture.
  #
  # PORTÉE : tout le compte, pas seulement le produit Ensemble. L'exonération
  # vaut pour l'entreprise entière — restreindre laisserait une taxe possible
  # ailleurs.
  #
  #   STRIPE_AUDIT_API_KEY=sk_live_… bin/rails stripe:desactiver_tva            # constate
  #   STRIPE_AUDIT_API_KEY=sk_live_… APPLIQUER=1 bin/rails stripe:desactiver_tva
  desc "Coupe la taxe automatique et pose la mention de franchise (APPLIQUER=1 pour écrire)"
  task desactiver_tva: :environment do
    ecrire = ENV["APPLIQUER"] == "1"
    StripeTaches.preparer_cle(ecrire ? "ÉCRITURE" : "constat seul")

    StripeTaches.couper_taxe_abonnements(ecrire)
    StripeTaches.poser_mention_brouillons(ecrire)
    # Un pied de page posé client par client ne couvre pas les futurs clients, et
    # celui du compte prime de toute façon. D'où l'opt-in.
    StripeTaches.poser_mention_clients(ecrire) if ENV["MENTION_CLIENTS"] == "1"

    puts "\nÀ faire dans le Dashboard — l'API ne l'expose pas, et c'est le bon levier :"
    puts "  Réglages → Facturation → Modèle de facture → pied de page :"
    puts "    #{StripeTaches::MENTION_TVA}"
    puts "  Il couvre toutes les factures, y compris des clients à venir."
    puts "\nAussi : la taxe automatique de la table tarifaire, à décocher là-bas."
    puts "\nRelancez sans APPLIQUER pour vérifier." if ecrire
  end

  # Les identifiants de prix sont propres à un mode : un `price_…` live est
  # introuvable en test, et le Checkout casse.
  #
  #   STRIPE_TEST_API_KEY=sk_test_… bin/rails stripe:clone_to_test
  #
  # La table tarifaire n'est PAS clonable : l'API n'expose aucune ressource
  # « pricing table ».
  desc "Clone le produit et les prix Stripe du live vers le test mode"
  task clone_to_test: :environment do
    live = ENV.fetch("STRIPE_API_KEY", nil)
    test = ENV.fetch("STRIPE_TEST_API_KEY", nil)
    abort "STRIPE_API_KEY manquante (clé source)." if live.blank?
    abort "STRIPE_TEST_API_KEY manquante (clé cible)." if test.blank?
    # Sans ce garde-fou, une clé live en cible dupliquerait le produit en production.
    abort "STRIPE_TEST_API_KEY n'est pas une clé de test." unless test.include?("_test_")
    abort "Les deux clés sont identiques : la source doit être la clé live." if live == test

    source = StripeTaches.lire_source(live)
    puts "Source : #{source[:produit].name.inspect} — #{source[:prix].size} prix actif(s)"

    Stripe.api_key = test
    produit = StripeTaches.produit_cible(source[:produit])
    puts "Produit test : #{produit.id}"

    # Hors de la boucle : la liste est identique d'un prix source à l'autre.
    deja = Stripe::Price.list(product: produit.id, active: true, limit: 100).data
    puts "\nÀ reporter dans votre .env de développement :"
    source[:prix].each do |prix_live|
      cree = StripeTaches.cloner_prix(prix_live, produit.id, deja)
      variable = prix_live.recurring.interval == "year" ? "STRIPE_PRICE_ANNUALY" : "STRIPE_PRICE_MONTHLY"
      puts "  #{variable}=#{cree.id}"
    end
    puts "\nRestent à faire à la main dans le Dashboard (test mode) :"
    puts "  STRIPE_SCHOOL_PRICING_ID  — l'API ne crée pas de table tarifaire"
    puts "  STRIPE_PUBLISHABLE_KEY    — la clé publiable du test mode"
    puts "  STRIPE_WEBHOOK_SECRET_KEY — celui que donne `stripe listen`"
  end
end
