work_plans = WorkPlan.where.not(student: nil)
puts "nb de WP est de #{work_plans.count}"
work_plans.each do |wp|
  wp.work_plan_domains.each do |domain|
    unless wp.student == domain.student
      domain.student = wp.student
      domain.save
      puts " on change #{domain.student} par #{wp.student} sur le domain #{domain.id}"
    end
    domain.work_plan_skills.each do |wps|
      unless wp.student == wps.student
        wps.student = wp.student
        wps.save
        puts " on change #{wps.student} par #{wp.student} sur le wps #{wps.id}"
      end
      puts "xxxxxxxxx fin de domain xxxxxxxxxxxxxx"
    end
  end
  puts "xxxxxxxxx fin du workplan xxxxxxxxxxxxxx"
end
