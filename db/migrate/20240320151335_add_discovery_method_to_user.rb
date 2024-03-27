class AddDiscoveryMethodToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :discovery_method, :string
  end
end
