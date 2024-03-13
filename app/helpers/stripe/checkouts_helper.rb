module Stripe::CheckoutsHelper
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
        customer:,
        locale: "fr",
        success_url: "#{default_url_options[:host]}/" + "subscriptions/success.html?session_id={CHECKOUT_SESSION_ID}",
        cancel_url: "#{default_url_options[:host]}/" + "subscriptions/new",
        subscription_data: {
          trial_period_days: 25 # Ajouter la période d'essai de 25 jours ici
        }
      }
    )
  end
end
