class Stripe::CheckoutsController < ApplicationController
  # def subscription_checkout
  #   school = current_user.school
  #   @customer = StripeHelper.get_or_create_customer(school)
  #   session = StripeHelper.create_subscription_checkout(@customer, school.subscription)
  #   authorize session
  #   redirect_to session.url, allow_other_host: true
  # end

  # def session_status
  #   session = Stripe::Checkout::Session.retrieve(params[:session_id])
  # {status: session.status, customer_email:  session.customer_details.email}.to_json
  # end
end
