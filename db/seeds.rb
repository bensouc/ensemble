# puts "searching Monna"
# user = User.where(first_name: 'Monna')

# monna_classroom = Classroom.where(user_id: user.ids).last
# students = %w[Syndjin Halil Ines Avsin Khaëlys Riteje Hamza Marame Arnold Kadidia Sarra Mikele Mila Wisdom ]
# puts "creating Student"
# students.each do |student|
#   Student.create!(first_name: student, classroom: monna_classroom)
# end
puts 'selecting all skills'
skills = Skill.all
skills.each do |skill|

  puts skill.grade
  skill.grade = 'CE1'
  skill.save!
  puts skill.grade
  puts '**********'
end
puts 'c ok'
