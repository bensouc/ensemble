module StripeHelper
  # get or cre
  def self.get_or_create_customer(user)
    Stripe.api_key = ENV["STRIPE_PUBLISHABLE_KEY"]
    customer = nil
    if user.stripe_customer_id?
      customer = Stripe::Customer.retrieve(user.stripe_customer_id)
    else
      customer = Stripe::Customer.create(email: user.email)
      user.stripe_customer_id = customer.id
      user.save
    end
    customer
  end
end
