class CreateBelts < ActiveRecord::Migration[6.0]
  def change
    create_table :belts do |t|
      t.references :student, null: false, foreign_key: true
      t.string :domain
      t.string :grade
      t.boolean :completed

      t.timestamps
    end
  end
end
