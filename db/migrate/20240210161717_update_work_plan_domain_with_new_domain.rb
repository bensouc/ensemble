class UpdateWorkPlanDomainWithNewDomain < ActiveRecord::Migration[7.0]
  def change
    rename_column :work_plan_domains, :domain, :name_domain
    add_reference :work_plan_domains, :domain, foreign_key: true

    # Update all WorkPlanDomain

    # update all WPD
    wpds = WorkPlanDomain.all
    # iterate on each skill
    wpds.each do |wpd|
      # get the right domain
      p wpd.work_plan.grade
      p wpd.name_domain
      new_domain = Domain.find_by(grade: wpd.work_plan.grade, name: wpd.name_domain)

      # link it to the skill via update
       wpd.update(domain: new_domain)
       p wpd
    end


  end
end
