class AddCodeToSchool < ActiveRecord::Migration[7.0]
  def change
    add_column :schools, :code, :string
  end
end
