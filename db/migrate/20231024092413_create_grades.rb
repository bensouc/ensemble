class CreateGrades < ActiveRecord::Migration[7.0]
  def change
    create_table :grades do |t|
      t.string :grade_level
      t.string :name
      t.references :school, foreign_key: true

      t.timestamps
    end
  end
end
