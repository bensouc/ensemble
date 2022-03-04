# puts "searching Monna"
# user = User.where(first_name: 'Monna')

# monna_classroom = Classroom.where(user_id: user.ids).last
# students = %w[Syndjin Halil Ines Avsin Khaëlys Riteje Hamza Marame Arnold Kadidia Sarra Mikele Mila Wisdom ]
# puts "creating Student"
# students.each do |student|
#   Student.create!(first_name: student, classroom: monna_classroom)
# end
puts 'selecting all WP'
wps = WorkPlan.all
wps.each do |wp|

  puts wp.grade
  wp.grade = 'CE1'
  wp.save!
  puts wp.grade
  puts '**********'
end
puts 'c ok'
