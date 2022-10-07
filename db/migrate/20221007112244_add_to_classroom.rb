class AddToClassroom < ActiveRecord::Migration[6.0]
  def change
    add_column :classrooms, :shared, :boolean
  end
end
