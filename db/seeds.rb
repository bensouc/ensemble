
# Update all WorkPlanDomain

    # # update all WPD
    # wpds = WorkPlanDomain.all
    # # iterate on each skill
    # wpds.each do |wpd|
    #   # get the right domain
    #   p wpd.work_plan.grade
    #   p wpd.name_domain
    #   new_domain = Domain.find_by(grade: wpd.work_plan.grade, name: wpd.name_domain)

    #   # link it to the skill via update
    #    wpd.update(domain: new_domain)
    #    p wpd
    # end

# update all Belt with new omain
 # update all WPD
    belts = Belt.all
    # iterate on each skill
    belts.each do |belt|
      # get the right domain
      p belt.grade
      p belt.name_domain
      new_domain = Domain.find_by(grade: belt.grade, name: belt.name_domain)

      # link it to the skill via update
       belt.update(domain: new_domain)
       p belt
    end
