class Removesareduser < ActiveRecord::Migration[6.0]
  def change
    remove_reference :work_plans, :shared_user, index: true
    # remove_column :work_plans, :shared_user, type: :integer
  end
end
