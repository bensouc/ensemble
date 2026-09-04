class Subscription < ApplicationRecord
  belongs_to :school

  # Les huit premiers sont ceux que Stripe émet. `incomplete_expired` et `paused`
  # manquaient : un enum lève ArgumentError sur une valeur inconnue, donc le
  # webhook répondait 500 et l'abonnement cessait d'être synchronisé.
  # `pause` et `ended` n'existent pas chez Stripe ; des lignes anciennes peuvent
  # les porter, on les garde sans jamais les alimenter.
  enum :status, {
    trialing: "trialing",
    active: "active",
    past_due: "past_due",
    canceled: "canceled",
    unpaid: "unpaid",
    incomplete: "incomplete",
    incomplete_expired: "incomplete_expired",
    paused: "paused",
    pause: "pause",
    ended: "ended"
  }

  ACCESS_GRANTING_STATUSES = %w[trialing active past_due]
  # validates :external_id, presence: true
  validates :rythm, inclusion: { in: %w[Annuel Mensuel] }
  scope :active_or_trialing, -> { where(status: ACCESS_GRANTING_STATUSES) }
  scope :recent, -> { order("current_period_end DESC NULLS LAST") }

  def active_or_trialing?
    ACCESS_GRANTING_STATUSES.include?(status)
  end

  # Le portail client de Stripe ne sait pas modifier un abonnement sur facture :
  # le client peut l'y annuler, consulter et régler ses factures, mais ni changer
  # sa quantité ni changer d'offre. C'est une limitation documentée du portail,
  # liée au `collection_method`, et le paiement de la facture n'y change rien.
  #
  # Nul se comporte comme avant la colonne — le portail reste proposé. Les lignes
  # anciennes se renseignent avec `bin/rails stripe:backfill_collection_method`.
  def sur_facture?
    collection_method == "send_invoice"
  end

  # Ce qu'une école peut régler elle-même chez Stripe.
  def modifiable_par_lecole?
    !sur_facture?
  end

  TARIFS = {
    monthly: 5,
    annualy: [0, 50, 50, 49, 49, 48, 48, 47, 47, 46]
  }

  # Le coût du barème pour une quantité, mêmes règles que
  # `calculate_subscription_controller.js` : seul l'INDICE se plafonne — le
  # tableau annuel s'arrête à 9 et le tarif unitaire ne bouge plus au-delà — la
  # quantité réelle restant le multiplicateur.
  #
  # Indicatif : c'est Stripe qui facture. Sert à ce qu'une demande de
  # modification arrive avec son montant, plutôt qu'un nombre de classes nu.
  def self.cout_annonce(rythm, quantity)
    quantite = quantity.to_i
    return TARIFS[:monthly] * quantite if rythm == "Mensuel"

    TARIFS[:annualy][quantite.clamp(0, TARIFS[:annualy].length - 1)] * quantite
  end
end
