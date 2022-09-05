class Addforeignkey < ActiveRecord::Migration[6.0]
  def change
    add_foreign_key :work_plans, :users, column: :shared_user_id
  end
end
