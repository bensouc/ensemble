class Subscription < ApplicationRecord
  belongs_to :school

  enum status: {
              trialing:   "trialing",
                active:   "active",
              past_due:   "past_due",
              canceled:   "canceled",
                unpaid:   "unpaid",
            incomplete:   "incomplete",
                 pause:   "pause",
                 ended:   "ended",
              }

  ACCESS_GRANTING_STATUSES = ["trialing", "active", "past_due"]
  # validates :external_id, presence: true

  scope :active_or_trialing, -> { where(status: ACCESS_GRANTING_STATUSES) }
  scope :recent, -> { order("current_period_end DESC NULLS LAST") }

  def active_or_trialing?
    ACCESS_GRANTING_STATUSES.include?(status)
  end

end
