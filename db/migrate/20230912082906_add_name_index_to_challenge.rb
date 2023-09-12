class AddNameIndexToChallenge < ActiveRecord::Migration[7.0]
  def change
    add_index :challenges, :name, unique: true
  end
end
