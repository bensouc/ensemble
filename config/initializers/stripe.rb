# frozen_string_literal: true

# La clé API, posée une fois au démarrage.
#
# Elle ne l'était nulle part : chaque appelant la réglait en première ligne —
# `StripeHelper`, le helper de Checkout, les services de webhook. Tout chemin qui
# l'oubliait partait donc avec celle du dernier passant, ou sans clé du tout. Une
# console `rails c` n'en avait aucune : le moindre `Stripe::Customer.create`
# tapé à la main levait un AuthenticationError.
#
# `Stripe.api_key` est global au processus ; les réglages en ligne qui subsistent
# ne font que réécrire la même valeur.
Stripe.api_key = ENV.fetch("STRIPE_API_KEY", nil)

# require "#{Rails.root}/app/services/stripe_subscription_created_service.rb"
# require "#{Rails.root}/app/services/stripe_customer_created_service.rb"
# require "#{Rails.root}/app/services/stripe_subscription_deleted_service.rb"
# require "#{Rails.root}/app/services/stripe_subscription_updated_service.rb"

# Rails.configuration.stripe = {
#   # ...
#   signing_secret: ENV["STRIPE_WEBHOOK_SECRET_KEY"],
# }

# # ...
# StripeEvent.signing_secret = Rails.configuration.stripe[:signing_secret]

# StripeEvent.configure do |events|
#   events.subscribe "customer.subscription.created", StripeSubscriptionCreatedService.new
#   events.subscribe "customer.created", StripeCustomerCreatedService.new
#   events.subscribe "customer.subscription.deleted", StripeSubscriptionDeletedService.new
#   events.subscribe "customer.subscription.updated", StripeSubscriptionUpdatedService.new

#   # customer.subscription.paused
#   # customer.subscription.pending_update_applied
#   # customer.subscription.pending_update_expired
#   # customer.subscription.resumed
#   # customer.subscription.trial_will_end

# end
