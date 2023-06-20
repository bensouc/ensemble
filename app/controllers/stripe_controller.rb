class StripeController < ApplicationController
  def create_portal_session
    Stripe.api_key = ENV["STRIPE_PUBLISHABLE_KEY"]

    # create or get strip customer
    customer = if current_user.stripe_customer_id?
        Stripe::Customer.retrieve(current_user.stripe_customer_id)
      else
        Stripe::Customer.create(email: current_user.email)
      end
    if current_user.stripe_customer_id.nil?
      current_user.stripe_customer_id = customer.id
      current_user.save
    end
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
