class CreateChallenges < ActiveRecord::Migration[6.0]
  def change
    create_table :challenges do |t|
      t.string :name
      t.references :skill, null: false, foreign_key: true
      t.boolean :shared
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
