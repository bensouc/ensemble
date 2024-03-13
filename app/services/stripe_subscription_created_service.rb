class StripeSubscriptionCreatedService
  def call(event)
    Stripe.api_key = ENV["STRIPE_API_KEY"]
    Subscription.create!(
      school: School.find_by(stripe_customer_id: event.data.object.customer),
      external_id: event.data.object.id,
      status: event.data.object.status,
      cancel_at_period_end: event.data.object.cancel_at_period_end,
      current_period_start: Time.at(event.data.object.current_period_start),
      current_period_end: Time.at(event.data.object.current_period_end)
    )
  end
end
