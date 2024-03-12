class SubscriptionsController < ApplicationController

  def school_pricing
      @customer = StripeHelper.get_or_create_customer(current_user.school)
      authorize Subscription
  end

  def on_boarding
    authorize Subscription
    @sequence = 1
  end

  def calculate
    binding.pry
  end

  def new
    @sequence = 3
    @school = current_user.school
    @subscription = Subscription.new
    authorize @subscription
    # @customer = StripeHelper.get_or_create_customer(current_user)
  end

  def create
  #   Stripe.api_key = ENV["STRIPE_API_KEY"]
  #   subscription = params[:type] == "annualy" ? SubscriptionPrice.current_yearly : SubscriptionPrice.current_monthly
  #   # prices = Stripe::Price.list(
  #   #   product: "prod_NeRtP4a4PdHkH9"
  #   # )

  #   session = Stripe::Checkout::Session.create({
  #     line_items: [{
  #       # Provide the exact Price ID (e.g. pr_1234) of the product you want to sell
  #       price: subscription.id,
  #       quantity: 1
  #     }],
  #     mode: "subscription",
  #     customer: Stripe::Customer.retrieve(current_user.stripe_customer_id),
  #     success_url:  "https://94b5-2a02-842b-fa7-e701-50b4-4ea0-d034-687a.ngrok-free.app" + 'subscriptions/success.html?session_id={CHECKOUT_SESSION_ID}',
  #     cancel_url: " https://94b5-2a02-842b-fa7-e701-50b4-4ea0-d034-687a.ngrok-free.app" + 'subscriptions/cancel.html',
  #   })

  # redirect session.url, allow_other_host: true

    # session = Stripe::Checkout::Session.create({
    #   line_items: [{
    #     # Provide the exact Price ID (e.g. pr_1234) of the product you want to sell
    #     price: subscription.id,
    #     quantity: 1,
    #   }],
    #   mode: "subscription",
    #   customer: Stripe::Customer.retrieve(current_user.stripe_customer_id),
    #   success_url: "https://YOUR_DOMAIN" + "/success.html",
    #   cancel_url: "https://YOU_DOMAIN" + "/cancel.html",
    # })
    # redirect_to session.url, allow_other_host: true
  end

  def cancel

  end

  def success
    authorize Subscription
    #     Stripe.api_key = ENV["STRIPE_API_KEY"]
    # @subscription = Stripe::Subscription.retrieve( current_user.subscription.external_id)
  end

end
