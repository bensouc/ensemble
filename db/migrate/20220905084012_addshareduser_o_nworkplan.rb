class AddshareduserONworkplan < ActiveRecord::Migration[6.0]
  def change
    add_reference :work_plans, :shared_user, index: true, null: true
  end
end
