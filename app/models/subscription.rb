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

  TARIFS = {
    monthly: 5,
    annualy: [0, 50, 50, 49, 49, 48, 48, 47, 47, 46]
  }
end
