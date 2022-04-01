# puts "searching Monna"
# user = User.where(first_name: 'Monna')

# monna_classroom = Classroom.where(user_id: user.ids).last
# students = %w[Syndjin Halil Ines Avsin Khaëlys Riteje Hamza Marame Arnold Kadidia Sarra Mikele Mila Wisdom ]
# puts "creating Student"
# students.each do |student|
#   Student.create!(first_name: student, classroom: monna_classroom)
# end

#UPDATE workplans skill with student#

wps_all = WorkPlanSkill.all
wps_all.each do |wps|
  unless wps.work_plan_domain.work_plan.student.nil?
    puts wps.work_plan_domain.work_plan.student.first_name
    wps.student = wps.work_plan_domain.work_plan.student
    wps.save!
    puts "#{wps.id} SAVED #{wps.student.first_name}"
  end
end
