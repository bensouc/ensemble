class RemoveGradeFromClassroom < ActiveRecord::Migration[7.0]
  def change
    remove_column :classrooms, :grade
  end
end
