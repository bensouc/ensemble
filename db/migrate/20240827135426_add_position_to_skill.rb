class AddPositionToSkill < ActiveRecord::Migration[7.0]
  def change
    add_column :skills, :position, :integer
    Domain.all.each do |domain|
      skills = domain.skills
      (1..7).to_a.each do |level|
        skills.where(level: level).order(:updated_at).each.with_index(1) do |skill, index|
        skill.update_column :position, index
        end
      end
    end
  end
end
