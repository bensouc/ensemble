class SubscriptionsController < ApplicationController
  def school_pricing
    @customer = StripeHelper.get_or_create_customer(current_user.school)
    authorize Subscription
  end

  def on_boarding
    authorize Subscription
    @sequence = 1
  end

  def new
    @sequence = 3
    @school = current_user.school
    @subscription = Subscription.new
    authorize @subscription
    # @customer = StripeHelper.get_or_create_customer(current_user)
  end

  def create
    @subcription = Subscription.new(params.require(:subscription).permit(:rythm, :quantity))
    authorize @subcription
    @subcription.school = current_user.school
    # @subcription.save
    @subcription.update(params.require(:costs).permit(:trial_end, :current_period_start, :current_period_end))
    @customer = StripeHelper.get_or_create_customer(current_user.school)
    session = StripeHelper.create_subscription_checkout(@customer, @subcription)
    redirect_to session.url, allow_other_host: true
  end

  def cancel
  end

  def success
    authorize Subscription
    #     Stripe.api_key = ENV["STRIPE_API_KEY"]
    # @subscription = Stripe::Subscription.retrieve( current_user.subscription.external_id)
  end
end
