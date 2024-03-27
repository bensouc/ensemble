class UpdateDomainToSKill < ActiveRecord::Migration[7.0]
  def change
    rename_column :skills, :domain, :name_domain
    add_reference :skills, :domain, foreign_key: true

    # update all skills
    skills = Skill.all
    # iterate on each skill
    skills.each do |skill|
      # get the right domain
      new_domain = Domain.find_by(grade_id: skill.grade_id, name: skill.name_domain)
      # link it to the skill via update
       skill.update(domain: new_domain)
       p skill
    end

  end
end
