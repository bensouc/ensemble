class StripeSubscriptionDeletedService
  def call(event)
    Stripe.api_key = ENV.fetch("STRIPE_API_KEY", nil)
    subcription = Subscription.find_by(
      external_id: event.data.object.id
    )
    subcription.status = "canceled"
    subcription.save!
  end
end
