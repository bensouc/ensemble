class AddLevelBelts < ActiveRecord::Migration[6.0]
  def change
    add_column :belts, :level, :integer, null: false
  end
end
