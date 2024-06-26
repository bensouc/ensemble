module Stripesubscription
  def self.update_or_create(event)
    # binding.pry
    subscription = Subscription.find_by(
      stripe_subscription_id: event.data.object.id,
    )
    school = School.find_by(stripe_customer_id: event.data.object.customer)
    subscription = school.subscription if subscription.nil?
    # binding.pry
    subscription.update!(
      stripe_subscription_id: event.data.object.id,
      status: event.data.object.status,
      quantity: event.data.object.quantity,
      cancel_at_period_end: event.data.object.cancel_at_period_end,
      current_period_start: Time.at(event.data.object.current_period_start),
      current_period_end: Time.at(event.data.object.current_period_end),
      plan_id: event.data.object.items.data[0].plan.id,
      # school: School.find_by(stripe_customer_id: event.data.object.customer),
      start_date: Time.at(event.data.object.start_date),
      trial_end: Time.at(event.data.object.trial_end)
    )
    subscription
  end

  def self.delete(stripe_subscription_id)
    subscription = Subscription.find_by(stripe_subscription_id: stripe_subscription_id)
    subscription.destroy
  end
end
