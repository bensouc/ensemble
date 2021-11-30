class CreateWorkPlanDomains < ActiveRecord::Migration[6.0]
  def change
    create_table :work_plan_domains do |t|
      t.string :domain
      t.integer :level
      t.references :work_plan, null: false, foreign_key: true

      t.timestamps
    end
  end
end
