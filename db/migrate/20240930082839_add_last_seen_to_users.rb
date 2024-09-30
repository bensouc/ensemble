class AddLastSeenToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :last_seen, :datetime
  end
end
