class AddSharerOnWorkplans < ActiveRecord::Migration[6.0]
  def change
    add_reference :work_plans, :shared_user_id, index: true
  end

end
