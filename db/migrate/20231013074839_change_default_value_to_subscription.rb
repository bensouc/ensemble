class ChangeDefaultValueToSubscription < ActiveRecord::Migration[7.0]
  def change
    change_column_default :subscriptions, :status, "incomplete"
  end
end
