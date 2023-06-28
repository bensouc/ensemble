require "#{Rails.root}/app/services/stripe_checkout_session_service.rb"
require "#{Rails.root}/app/services/stripe_customer_created_service.rb"

Rails.configuration.stripe = {
  # ...
  signing_secret: ENV["STRIPE_WEBHOOK_SECRET_KEY"],
}

# ...
StripeEvent.signing_secret = Rails.configuration.stripe[:signing_secret]

StripeEvent.configure do |events|
  events.subscribe "customer.subscription.created", StripeCheckoutSessionService.new
  events.subscribe "customer.created", StripeCustomerCreatedService.new
end
