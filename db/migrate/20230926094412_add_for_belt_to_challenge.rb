class AddForBeltToChallenge < ActiveRecord::Migration[7.0]
  def change
    add_column :challenges, :for_belt, :boolean, default: false
  end
end
