# puts "searching Monna"
# user = User.where(first_name: 'Monna')

# monna_classroom = Classroom.where(user_id: user.ids).last
# students = %w[Syndjin Halil Ines Avsin Khaëlys Riteje Hamza Marame Arnold Kadidia Sarra Mikele Mila Wisdom ]
# puts "creating Student"
# students.each do |student|
#   Student.create!(first_name: student, classroom: monna_classroom)
# end

#UPDATE workplans skill with student if wp has a student#
puts "UPDATE workplans skill with student"
wps_all = WorkPlanSkill.all
wps_all.each do |wps|
  unless wps.work_plan_domain.work_plan.student.nil?
    if wps.student.nil?
      puts wps.work_plan_domain.work_plan.student.first_name
      wps.student = wps.work_plan_domain.work_plan.student

      wps.save!
      puts "#{wps.id} SAVED #{wps.student.first_name}"
    end
  end
end
puts "UPDATE workplans skill with student DONE"


#UPDATE workplandomains skill with student wp has a student#
puts "UPDATE workplandomains skill with student"

wpds_all = WorkPlanDomain.all
wpds_all.each do |wpd|
  unless wpd.work_plan.student.nil?
    if wpd.student.nil?
      puts wpd.work_plan.student.first_name
      wpd.student = wpd.work_plan.student

      wpd.save!
      puts "#{wpd.id} SAVED #{wpd.student.first_name}"
    end
  end
end
puts "UPDATE workplandomains skill with student DONE"
