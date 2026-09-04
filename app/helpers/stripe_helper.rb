# frozen_string_literal: true

# Le client Stripe d'une école. Le Checkout comme le portail de facturation en
# exigent un qui existe encore.
module StripeHelper
  # Renvoie le client Stripe de l'école, et en crée un neuf si l'id en base ne
  # désigne plus personne.
  #
  # Un id en base ne prouve rien, et l'échec ne prend pas la même forme selon la
  # cause — c'est tout le piège :
  #
  # - client **supprimé** depuis le Dashboard : `retrieve` répond **200**, avec un
  #   objet réduit à `{ id:, deleted: true }`. Aucune exception, donc : un simple
  #   `rescue` laissait passer un client mort, et l'id périmé restait en base.
  # - id **inconnu** (jamais créé, ou créé en test mode et lu en live) :
  #   `retrieve` répond 404 et lève `InvalidRequestError`.
  #
  # Dans les deux cas la seule issue est un client neuf — un client supprimé ne se
  # restaure pas, et son historique de facturation est perdu pour le portail.
  # L'appelant qui comptait dessus compare l'id renvoyé à celui qu'il avait.
  def self.get_or_create_customer(client)
    Stripe.api_key = ENV.fetch("STRIPE_API_KEY", nil)
    return create_customer(client) unless client.stripe_customer_id?

    customer = retrieve(client)
    return create_customer(client) if customer.nil? || customer[:deleted]

    customer
  end

  # `[]` comme partout où l'on lit du Stripe dans ce dépôt : il rend nil pour une
  # clé absente, sans dépendre de ce que le SDK déclare comme attribut de la
  # classe. Un client vivant ne porte pas `deleted` et se lit donc nil.
  def self.retrieve(client)
    Stripe::Customer.retrieve(client.stripe_customer_id)
  rescue Stripe::InvalidRequestError => e
    Rails.logger.warn("[stripe] client #{client.stripe_customer_id.inspect} inconnu — #{e.message}")
    nil
  end

  # Le nom et l'id en base voyagent avec : sans eux le Dashboard n'affiche qu'un
  # email, et créer l'abonnement sur facture à la main revient à chercher la bonne
  # école à l'aveugle.
  def self.create_customer(client)
    attributs = { email: client.email, name: client.try(:name) }.compact
    attributs[:metadata] = { client.class.name.underscore => client.id }
    customer = Stripe::Customer.create(attributs)
    # Écrit sans repasser par les validations : une école dont la ligne est par
    # ailleurs invalide — deux écoles qui partagent un email, un email ancien
    # manquant — verrait sinon son id perdu en silence, et un client vide créé
    # chez Stripe à chaque clic.
    client.update_column(:stripe_customer_id, customer.id) # rubocop:disable Rails/SkipsModelValidations
    customer
  end

  private_class_method :retrieve, :create_customer
end
