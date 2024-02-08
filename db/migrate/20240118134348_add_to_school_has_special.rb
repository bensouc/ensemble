class AddToSchoolHasSpecial < ActiveRecord::Migration[7.0]
  def change
    add_column :schools, :special_domains, :boolean, default: false
  end
end
