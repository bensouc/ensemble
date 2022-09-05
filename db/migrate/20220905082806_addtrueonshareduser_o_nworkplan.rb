class AddtrueonshareduserONworkplan < ActiveRecord::Migration[6.0]
  def change
    change_column_null :work_plans, :shared_user_id, true
  end
end
