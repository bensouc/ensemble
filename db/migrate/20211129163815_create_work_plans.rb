class CreateWorkPlans < ActiveRecord::Migration[6.0]
  def change
    create_table :work_plans do |t|
      t.string :name
      t.references :user, null: false, foreign_key: true
      t.references :student, null: true, foreign_key: true

      t.timestamps
    end
  end
end
