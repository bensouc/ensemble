require "open-uri"

# puts "destroying current data"
# WorkPlanSkill.destroy_all
# puts "destroying current WorkPlanSkill"
# WorkPlanDomain.destroy_all
# puts "destroying current WorkPlanDomain "
# Challenge.destroy_all
# puts "destroying current Challenge "
# Skill.destroy_all
# puts "destroying current Skill "
# WorkPlan.destroy_all
# Student.destroy_all
# Classroom.destroy_all
# User.destroy_all



# user1 = User.create!(email:'toto@gmail.com', password:'secret', first_name:'toto', last_name: 'titi')
# file = URI.open('https://cdn0.iconfinder.com/data/icons/basic-50/24/essential_basic_ui_user-512.png')
# user1.photo.attach(io: file, filename: 'essential_basic_ui_user-512.png', content_type: 'image/png')

# puts "creating user1"
# user1 = User.create!(email:'celine@gmail.com', password:'secret', first_name:'Céline', last_name: 'Chevalier')
# puts "creating user1 OK"

# puts "creating user2"
# user2 = User.create!(email:'monna@gmail.com', password:'secret', first_name:'Monna', last_name: 'Lemoine')
# file2 = URI.open('https://res.cloudinary.com/bensoucdev/image/upload/v1644762709/ydt2oy5frv5n4yhgo1hjy1wv4j9s.jpg')
# user2.avatar.attach(io: file2, filename: 'ydt2oy5frv5n4yhgo1hjy1wv4j9s.jpg', content_type: 'image/jpg')
# puts "creating user2 OK"




# puts "creating Classroom"

# classroom1 = Classroom.create!(grade: 'CE1', user: user1)
# classroom2 = Classroom.create!(grade: 'CE1', user: user2)


# puts "creating Student"

# # student1 = Student.create!(first_name: 'Adèle', classroom: classroom1)
# students = %w[Pierre Jade Marame Jeanne Enora Kenji Halil Adèle Ines Hamza Riteje Sam Mila Wisdom Mikele]
# students.sort!
# students.each do |student|
#   Student.create!(first_name: student, classroom: classroom1)
# end

# puts "destroy all  geometrie et grandeur"
# Skill.where(domain: 'Géométrie').destroy_all
# puts "destroy all  geometrie et grandeur => OK"
# puts '******************'
# puts "destroy all  geometrie et grandeur"
# Skill.where(domain: 'grandeurs et Mesures').destroy_all
# puts "destroy all  geometrie et grandeur => OK"
# puts '******************'

# puts "searching Monna"
# user = User.where(first_name: 'Monna')

# monna_classroom = Classroom.where(user_id: user.ids).last
# students = %w[Syndjin Halil Ines Avsin Khaëlys Riteje Hamza Marame Arnold Kadidia Sarra Mikele Mila Wisdom ]
# puts "creating Student"
# students.each do |student|
#   Student.create!(first_name: student, classroom: monna_classroom)
# end

# # student1 = Student.create!(first_name: 'Adèle', classroom: classroom1)
# students = %w[Pierre Jade Marame Jeanne Enora Kenji Halil Adèle Ines Hamza Riteje Sam Mila Wisdom Mikele]
# students.sort!
# students.each do |student|
#   Student.create!(first_name: student, classroom: classroom1)
# end
