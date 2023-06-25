class CreateSubscriptions < ActiveRecord::Migration[7.0]
  def change
    create_table :subscriptions do |t|
      t.references :user, foreign_key: true, null: false, index: true
      t.string :external_id, null: false, default: ""
      t.string :status, null: false
      t.boolean :cancel_at_period_end, null: false, default: false
      t.date :current_period_start, null: false
      t.date :current_period_end, null: false

      t.timestamps
    end
  end
end
