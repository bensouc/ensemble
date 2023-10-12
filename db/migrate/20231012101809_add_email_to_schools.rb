class AddEmailToSchools < ActiveRecord::Migration[7.0]
  def change
    add_column :schools, :email, :string
  end
end
