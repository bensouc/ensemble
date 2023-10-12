# frozen string literal comment
class Stripe::StripeController < ApplicationController
  def create_portal_session
    # Stripe.api_key = ENV["STRIPE_API_KEY"]
    # Authenticate your customer.
    session = Stripe::BillingPortal::Session.create({
      customer: current_user.stripe_customer_id,
      return_url: "https://app-ensemble.fr/dashboard"
    })
    redirect_to session.url, allow_other_host: true
  end
end
