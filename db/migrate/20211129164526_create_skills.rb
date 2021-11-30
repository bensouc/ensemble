class CreateSkills < ActiveRecord::Migration[6.0]
  def change
    create_table :skills do |t|
      t.string :domain
      t.integer :level
      t.string :name
      t.string :symbol

      t.timestamps
    end
  end
end
