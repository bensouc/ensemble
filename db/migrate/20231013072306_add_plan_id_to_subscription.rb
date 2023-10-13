class AddPlanIdToSubscription < ActiveRecord::Migration[7.0]
  def change
    add_column :subscriptions, :plan_id, :string
  end
end
