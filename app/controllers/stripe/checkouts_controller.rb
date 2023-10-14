class Stripe::CheckoutsController < ApplicationController
  def create_subscription_checkout
    Stripe.api_key = ENV["STRIPE_API_KEY"]
    session = Stripe::Checkout::Session.create({
      success_url: "https://app-ensemble.fr/subscriptions/success",
      line_items: [
        { price: "price_1O0jx5D36LSTpclfjnLgQSRt", quantity: 2 },
      ],
      mode: "subscription",
      # customer: current_user.school.stripe_customer_id,
      customer_email: current_user.school.email,
    })
    authorize session
    redirect_to session.url, allow_other_host: true
  end
end
