class SubscriptionsController < ApplicationController
  def new
    @subscription = Subscription.new
    @customer = StripeHelper.get_or_create_customer(current_user)
  end

  def create
    Stripe.api_key = ENV["STRIPE_API_KEY"]
    session = Stripe::Checkout::Session.create({
      line_items: [{
        # Provide the exact Price ID (e.g. pr_1234) of the product you want to sell
        price: "price_1NKgoWD36LSTpclfroqOKpuI",
        quantity: 1,
      }],
      mode: "subscription",
      customer: Stripe::Customer.retrieve(current_user.stripe_customer_id),
      success_url: "https://YOUR_DOMAIN" + "/success.html",
      cancel_url: "https://YOU_DOMAIN" + "/cancel.html",
    })
    redirect_to session.url, allow_other_host: true
  end
end
