class StripeCustomerCreatedService
  def call(event)
    Stripe.api_key = ENV["STRIPE_API_KEY"]
    # get user and add stripe id
    # customer = event.data.object.
    user = User.find_by(email: event.data.object.email)
    user.stripe_customer_id = event.data.object.id
    user.save!
  end
end
