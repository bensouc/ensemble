class RemoveGradeFromSkill < ActiveRecord::Migration[7.0]
  def change
    remove_column :skills, :grade
  end
end
