class StripeSubscriptionUpdatedService
  def call(event)
    Stripe.api_key = ENV["STRIPE_API_KEY"]
    subcription = Subscription.find_by(
      external_id: event.data.object.id,
    )
    subcription.update!(
      status: event.data.object.status,
      cancel_at_period_end: event.data.object.cancel_at_period_end,
      current_period_start: Time.at(event.data.object.current_period_start),
      current_period_end: Time.at(event.data.object.current_period_end),
    )
  end
end
