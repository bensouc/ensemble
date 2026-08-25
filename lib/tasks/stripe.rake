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

  # Auto-entrepreneur en franchise de TVA : rien ne doit ajouter de taxe. Cette
  # tâche ne modifie rien, elle constate.
  #
  #   STRIPE_AUDIT_API_KEY=sk_live_… bin/rails stripe:audit_tva
  desc "Vérifie qu'aucune TVA n'est appliquée (lecture seule)"
  task audit_tva: :environment do
    cle = ENV.fetch("STRIPE_AUDIT_API_KEY", nil) || ENV.fetch("STRIPE_API_KEY", nil)
    abort "Aucune clé." if cle.blank?
    Stripe.api_key = cle
    puts "Mode : #{cle.include?('_live_') ? 'LIVE' : 'test'}\n\n"
    auditer_compte
    auditer_prix
    auditer_abonnements
    auditer_factures
    auditer_mention
  end

  # Le pied de page par défaut du compte n'est pas lisible par l'API — c'est un
  # modèle de document, réglé dans le Dashboard. On le constate donc sur les
  # factures qu'il produit : une facture émise APRÈS le réglage doit le porter.
  def auditer_mention
    puts "\nMention de franchise sur les dernières factures :"
    recentes = Stripe::Invoice.list(limit: 10).data
    if recentes.empty?
      puts "  aucune facture à examiner"
      return
    end
    recentes.each { |f| puts ligne_de_mention(f) }
    puts "  Une facture antérieure au réglage ne la portera jamais : le pied de"
    puts "  page est figé à la finalisation."
  end

  # Sans immatriculation fiscale, Stripe Tax ne prélève rien même s'il est actif.
  # C'est ce qui protège aujourd'hui : en ajouter une déclencherait la TVA sur
  # tous les abonnements portant `automatic_tax`.
  def auditer_compte
    puts "Stripe Tax (compte) : statut=#{Stripe::Tax::Settings.retrieve.status}"
    immat = Stripe::Tax::Registration.list(status: "active", limit: 100).data
    puts "Immatriculations fiscales actives : #{immat.size}#{alerte(immat.any?)}"
    immat.each { |r| puts immatriculation(r) }
  rescue Stripe::StripeError => e
    puts "Stripe Tax : non consultable (#{e.class})"
  end

  def immatriculation(reg)
    "  #{reg.country} #{reg.type} depuis #{Time.zone.at(reg.active_from).to_date}"
  end

  def ligne_de_mention(facture)
    etat = facture.footer.to_s.include?("293 B") ? "mention présente" : "SANS MENTION"
    format("  %<id>-28s %<date>s %<etat>s", id: facture.id,
                                            date: Time.zone.at(facture.created).to_date, etat:)
  end

  def auditer_prix
    puts "\nPrix avec un comportement fiscal explicite :"
    fautifs = []
    prix = Stripe::Price.list(active: true, limit: 100)
    prix.auto_paging_each { |p| fautifs << p unless p.tax_behavior == "unspecified" }
    puts fautifs.empty? ? "  aucun — tous en `unspecified`" : fautifs.map { |p| "  #{p.id} #{p.tax_behavior}" }
  end

  def auditer_abonnements
    puts "\nAbonnements avec taxe automatique :"
    avec = []
    Stripe::Subscription.list(limit: 100).auto_paging_each { |s| avec << s if s.automatic_tax&.enabled }
    puts avec.empty? ? "  aucun" : avec.map { |s| "  #{s.id} (#{s.status})#{alerte(true)}" }
  end

  def auditer_factures
    puts "\nFactures récentes portant une taxe :"
    avec = Stripe::Invoice.list(limit: 100).data.filter_map { |f| ligne_de_taxe(f) }
    puts avec.empty? ? "  aucune — 0 € de taxe partout" : avec
  end

  def ligne_de_taxe(facture)
    taxe = facture.total_taxes.to_a.sum { |t| t.respond_to?(:amount) ? t.amount.to_i : 0 }
    return nil unless taxe.positive?

    format("  %<id>-28s total=%<t>8.2f taxe=%<x>6.2f",
           id: facture.id, t: facture.total.to_i / 100.0, x: taxe / 100.0)
  end

  def alerte(condition) = condition ? "  <-- À VÉRIFIER" : ""

  # Franchise en base de TVA : aucune taxe ne doit être calculée, et la mention
  # légale doit figurer sur chaque facture.
  #
  # PORTÉE : tout le compte, pas seulement le produit Ensemble. L'exonération
  # vaut pour l'entreprise entière, pas pour un produit — restreindre serait
  # laisser une taxe possible ailleurs.
  #
  #   STRIPE_AUDIT_API_KEY=sk_live_… bin/rails stripe:desactiver_tva          # constate
  #   STRIPE_AUDIT_API_KEY=sk_live_… APPLIQUER=1 bin/rails stripe:desactiver_tva
  def mention_tva = "TVA non applicable, art. 293 B du CGI"

  desc "Coupe la taxe automatique et pose la mention de franchise (APPLIQUER=1 pour écrire)"
  task desactiver_tva: :environment do
    cle = ENV.fetch("STRIPE_AUDIT_API_KEY", nil) || ENV.fetch("STRIPE_API_KEY", nil)
    abort "Aucune clé." if cle.blank?
    Stripe.api_key = cle
    ecrire = ENV["APPLIQUER"] == "1"
    puts "Mode #{cle.include?('_live_') ? 'LIVE' : 'test'} — #{ecrire ? 'ÉCRITURE' : 'constat seul'}\n\n"

    couper_taxe_abonnements(ecrire)
    poser_mention_brouillons(ecrire)
    # Un pied de page posé client par client ne couvre pas les futurs clients, et
    # celui du compte prime de toute façon. D'où l'opt-in.
    poser_mention_clients(ecrire) if ENV["MENTION_CLIENTS"] == "1"

    puts "\nÀ faire dans le Dashboard — l'API ne l'expose pas, et c'est le bon levier :"
    puts "  Réglages → Facturation → Modèle de facture → pied de page :"
    puts "    #{mention_tva}"
    puts "  Il couvre toutes les factures, y compris des clients à venir."
    puts "\nAussi : la taxe automatique de la table tarifaire, à décocher là-bas."
    puts "\nRelancez sans APPLIQUER pour vérifier." if ecrire
  end

  def couper_taxe_abonnements(ecrire)
    vises = []
    Stripe::Subscription.list(limit: 100).auto_paging_each { |s| vises << s if s.automatic_tax&.enabled }
    puts "Abonnements avec taxe automatique : #{vises.size}"
    vises.each do |s|
      puts "  #{s.id} (#{s.status})#{' -> coupée' if ecrire}"
      Stripe::Subscription.update(s.id, automatic_tax: { enabled: false }) if ecrire
    end
  end

  def poser_mention_clients(ecrire)
    vises, total = clients_sans_mention
    puts "\nClients sans la mention : #{vises.size} sur #{total}"
    puts "  (une écriture par client — préférez le pied de page du compte)" if vises.size > 50
    vises.each do |c|
      puts "  #{c.id} #{c.email}#{' -> mention posée' if ecrire}"
      Stripe::Customer.update(c.id, invoice_settings: { footer: mention_tva }) if ecrire
    end
  end

  def clients_sans_mention
    vises = []
    total = 0
    Stripe::Customer.list(limit: 100).auto_paging_each do |c|
      total += 1
      vises << c unless c.invoice_settings&.footer.to_s.include?("293 B")
    end
    [vises, total]
  end

  # Le pied de page d'une facture est figé à sa finalisation : seules les
  # brouillons peuvent encore le recevoir.
  def poser_mention_brouillons(ecrire)
    vises = []
    brouillons = Stripe::Invoice.list(status: "draft", limit: 100)
    brouillons.auto_paging_each { |f| vises << f unless f.footer.to_s.include?("293 B") }
    puts "\nFactures brouillon sans la mention : #{vises.size}"
    vises.each do |f|
      puts "  #{f.id}#{' -> mention posée' if ecrire}"
      Stripe::Invoice.update(f.id, footer: mention_tva) if ecrire
    end
  end

  desc "Clone le produit et les prix Stripe du live vers le test mode"
  task clone_to_test: :environment do
    live = ENV.fetch("STRIPE_API_KEY", nil)
    test = ENV.fetch("STRIPE_TEST_API_KEY", nil)

    abort "STRIPE_API_KEY manquante (clé source)." if live.blank?
    abort "STRIPE_TEST_API_KEY manquante (clé cible)." if test.blank?
    # Sans ce garde-fou, une clé live en cible dupliquerait le produit en production.
    abort "STRIPE_TEST_API_KEY n'est pas une clé de test." unless test.include?("_test_")
    abort "Les deux clés sont identiques : la source doit être la clé live." if live == test

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
  # Se lance AVANT de basculer STRIPE_API_KEY en test : c'est elle qui sert de source.
  # Une fois la bascule faite, le produit live devient introuvable — d'où ce message
  # plutôt qu'une erreur Stripe brute.
  def lire_source(cle)
    Stripe.api_key = cle
    produit = begin
      Stripe::Product.retrieve(produit_live)
    rescue Stripe::AuthenticationError
      abort "STRIPE_API_KEY refusée par Stripe."
    rescue Stripe::InvalidRequestError
      abort "Produit #{produit_live} introuvable avec STRIPE_API_KEY.\n" \
            "Cette tâche doit tourner AVANT de basculer STRIPE_API_KEY en test : " \
            "c'est cette clé qui lit le produit live."
    end
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
