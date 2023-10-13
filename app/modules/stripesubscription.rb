module Stripesubscription
  def self.update_or_create(event)
    # binding.pry
    subscription = Subscription.find_by(
      stripe_subscription_id: event.data.object.id,
    )
    subscription = Subscription.new(stripe_subscription_id: event.data.object.id) if subscription.nil?
    # binding.pry
    subscription.update(
      status: event.data.object.status,
      quantity: event.data.object.quantity,
      cancel_at_period_end: event.data.object.cancel_at_period_end,
      current_period_start: Time.at(event.data.object.current_period_start),
      current_period_end: Time.at(event.data.object.current_period_end),
      plan_id: event.data.object.items.data[0].plan.id,
      school: School.find_by(stripe_customer_id: event.data.object.customer),
    )
    subscription
  end
end
