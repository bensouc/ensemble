class RemoveGradeBelt < ActiveRecord::Migration[7.0]
 def change
  remove_column :belts, :grade
end
end
