class CreateSharedClassrooms < ActiveRecord::Migration[6.0]
  def change
    create_table :shared_classrooms do |t|
      t.references :user, null: false, foreign_key: true
      t.references :classroom, null: false, foreign_key: true

      t.timestamps
    end
  end
end
