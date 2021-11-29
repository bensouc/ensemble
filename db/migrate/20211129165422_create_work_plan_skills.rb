class CreateWorkPlanSkills < ActiveRecord::Migration[6.0]
  def change
    create_table :work_plan_skills do |t|
      t.references :work_plan_domain, null: false, foreign_key: true
      t.references :skill, null: false, foreign_key: true
      t.string :kind
      t.references :challenge, null: true, foreign_key: true

      t.timestamps
    end
  end
end
