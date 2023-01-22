class AddSubDomainToSkill < ActiveRecord::Migration[6.0]
  def change
    add_column :skills, :sub_domain, :string, null: true
  end
end
