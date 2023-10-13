module StripeHelper
  # get or cre
  # StripeHelper.get_or_create_customer(current_user)
  def self.get_or_create_customer(client)
    Stripe.api_key = ENV["STRIPE_API_KEY"]
    customer = nil
    if client.stripe_customer_id?
      customer = Stripe::Customer.retrieve(client.stripe_customer_id)
      if customer['deleted'] == true
        customer = Stripe::Customer.create(email: client.email)
        client.stripe_customer_id = customer.id
        client.save
      end
    else
      customer = Stripe::Customer.create(email: client.email)
      client.stripe_customer_id = customer.id
      client.save
    end
    customer
  end
end
