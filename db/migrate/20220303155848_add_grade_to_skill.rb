class AddGradeToSkill < ActiveRecord::Migration[6.0]
  def change
    add_column :skills, :grade, :string
  end
end
