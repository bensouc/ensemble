class StripeSubscriptionDeletedService
  def call(event)
    Stripe.api_key = ENV["STRIPE_API_KEY"]
    subcription = Subscription.find_by(
      external_id: event.data.object.id,
    )
    subcription.status = "canceled"
    subcription.save!
  end
end
