class RemoveFkSharedUserOnWorkPlans < ActiveRecord::Migration[6.0]
  def change
    remove_foreign_key :work_plans, column: :shared_user_id
  end
end
