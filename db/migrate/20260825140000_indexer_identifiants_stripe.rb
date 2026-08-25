# frozen_string_literal: true

# Le webhook interroge ces deux colonnes à CHAQUE événement Stripe —
# `Subscription.find_by(stripe_subscription_id:)` puis, en dernier recours,
# `School.find_by(stripe_customer_id:)`. Aucune n'était indexée : deux scans
# séquentiels par événement.
class IndexerIdentifiantsStripe < ActiveRecord::Migration[7.1]
  def change
    add_index :subscriptions, :stripe_subscription_id
    add_index :schools, :stripe_customer_id
  end
end
