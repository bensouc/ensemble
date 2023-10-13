class AddToSubscription < ActiveRecord::Migration[7.0]
  def change
    rename_column :subscriptions, :external_id, :stripe_subscription_id
    add_reference :subscriptions, :school, foreign_key: true
    add_column :subscriptions, :quantity, :integer
  end
end
