class AddStartDateToSubscriptions < ActiveRecord::Migration[7.0]
  def change
    add_column :subscriptions, :start_date, :date
    add_column :subscriptions, :trial_end, :date
  end
end
