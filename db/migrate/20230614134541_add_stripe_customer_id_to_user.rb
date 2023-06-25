class AddStripeCustomerIdToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :stripe_customer_id, :text
  end
end
