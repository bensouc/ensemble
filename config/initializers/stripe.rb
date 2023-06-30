require "#{Rails.root}/app/services/stripe_subscription_created_service.rb"
require "#{Rails.root}/app/services/stripe_customer_created_service.rb"
require "#{Rails.root}/app/services/stripe_subscription_deleted_service.rb"
require "#{Rails.root}/app/services/stripe_subscription_updated_service.rb"

Rails.configuration.stripe = {
  # ...
  signing_secret: ENV["STRIPE_WEBHOOK_SECRET_KEY"],
}

# ...
StripeEvent.signing_secret = Rails.configuration.stripe[:signing_secret]

StripeEvent.configure do |events|
  events.subscribe "customer.subscription.created", StripeSubscriptionCreatedService.new
  events.subscribe "customer.created", StripeCustomerCreatedService.new
  events.subscribe "customer.subscription.deleted", StripeSubscriptionDeletedService.new
  events.subscribe "customer.subscription.updated", StripeSubscriptionUpdatedService.new

  # customer.subscription.paused
  # customer.subscription.pending_update_applied
  # customer.subscription.pending_update_expired
  # customer.subscription.resumed
  # customer.subscription.trial_will_end

end
