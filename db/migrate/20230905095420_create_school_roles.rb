class CreateSchoolRoles < ActiveRecord::Migration[7.0]
  def change
    create_table :school_roles do |t|
      t.references :user, foreign_key: true
      t.references :school, foreign_key: true
      t.boolean :super_teacher, default: false

      t.timestamps
    end
  end
end
