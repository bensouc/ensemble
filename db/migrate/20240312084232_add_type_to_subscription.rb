class AddTypeToSubscription < ActiveRecord::Migration[7.0]
  def change
    add_column :subscriptions, :type, :string, default: "annuel"
  end
end
