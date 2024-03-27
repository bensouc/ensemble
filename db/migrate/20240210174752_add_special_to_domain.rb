class AddSpecialToDomain < ActiveRecord::Migration[7.0]
  def change
    add_column :domains, :special, :boolean
  end
end
