class ChangeSubTable < ActiveRecord::Migration[7.0]
  def change
    remove_reference :subscriptions, :user, foreign_key: true, index: true
  end
end
