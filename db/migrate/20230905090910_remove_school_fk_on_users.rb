class RemoveSchoolFkOnUsers < ActiveRecord::Migration[7.0]
  def change
    remove_reference :users, :school, foreign_key: true, index: false
  end
end
