class StripeController < ApplicationController
  def create_portal_session
    Stripe.api_key = ENV["STRIPE_PUBLISHABLE_KEY"]

    # create or get strip customer
    customer = StripeHelper.get_or_create_customer(current_user)
    # raise

    # Authenticate your customer.
    session = Stripe::BillingPortal::Session.create({
      customer: customer,
      return_url: "https://app-ensemble.fr/dashboard",
    })
    redirect_to session.url, allow_other_host: true, notice: "Watch it, mister!"
  end

  private
end
