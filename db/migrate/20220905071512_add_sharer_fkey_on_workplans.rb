class AddSharerFkeyOnWorkplans < ActiveRecord::Migration[6.0]
  def change
    rename_column :work_plans, :shared_user_id_id, :shared_user_id
    add_foreign_key :work_plans, :users, column: :shared_user_id
  end
end
