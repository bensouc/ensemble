class AddDomainToBelt < ActiveRecord::Migration[7.0]
  def change
    rename_column :belts, :domain, :name_domain
    add_reference :belts, :domain, foreign_key: true
  end
end
