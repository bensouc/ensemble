module StripeHelper
  # get or cre
  # StripeHelper.get_or_create_customer(current_user)
  def self.get_or_create_customer(client)
    Stripe.api_key = ENV.fetch("STRIPE_API_KEY", nil)
    customer = nil
    if client.stripe_customer_id?
      begin
        customer = Stripe::Customer.retrieve(client.stripe_customer_id)
      # TODO: check if customer is valid / not deleted
      rescue Stripe::InvalidRequestError => e
        raise
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
