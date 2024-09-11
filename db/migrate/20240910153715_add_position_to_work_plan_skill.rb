class AddPositionToWorkPlanSkill < ActiveRecord::Migration[7.0]
  def change
    add_column :work_plan_skills, :position, :integer
    WorkPlanDomain.all.each do |to_list|
      to_list.work_plan_skills.sort_by{|wps| wps.skill.position}.each.with_index(1) do |todo_item, index|
        todo_item.update_column :position, index
      end
    end
  end
end
