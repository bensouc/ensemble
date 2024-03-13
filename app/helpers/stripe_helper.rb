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

  def self.create_subscription_checkout(customer, subscription)
    Stripe.api_key = ENV.fetch("STRIPE_API_KEY", nil)
    Stripe::Checkout::Session.create(
      {
      line_items: [{
        # Provide the exact Price ID (e.g. pr_1234) of the product you want to sell
        price: subscription.rythm == "Annuel" ? "price_1OtX5nD36LSTpclfRBqKPWul" : "price_1OtX5nD36LSTpclfOFDkQVHe",
        quantity: subscription.quantity
      }],
      mode: "subscription",
      customer: customer,
      locale: "fr",
      success_url: "https://app-ensemble.fr" + "subscriptions/success.html?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: "https://app-ensemble.fr" + "subscriptions/new",
      subscription_data: {
          trial_period_days: 25 # Ajouter la période d'essai de 25 jours ici
        }
      }
    )
  end
end
