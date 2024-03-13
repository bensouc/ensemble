class Subscription < ApplicationRecord
  belongs_to :school

  enum status: {
    trialing: "trialing",
    active: "active",
    past_due: "past_due",
    canceled: "canceled",
    unpaid: "unpaid",
    incomplete: "incomplete",
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
