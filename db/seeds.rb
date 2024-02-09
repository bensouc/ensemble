  # populate table with existing value
  Domain.destroy_all
  School.all.each do  |school|
    school.grades.each do |grade|
      p grade
      # get domains from grade
      # iterate and create new domains
      p domain_names = WorkPlanDomain::DOMAINS[grade.grade_level]
      domain_names.each {|domain| Domain.create!(name: domain, grade: grade)} unless domain_names.empty?
    end
  end
