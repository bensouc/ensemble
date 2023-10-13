class AddStripeCustomerIdToSchools < ActiveRecord::Migration[7.0]
  def change
    add_column :schools, :stripe_customer_id, :string
  end
end
