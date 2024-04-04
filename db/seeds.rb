# require "open-uri"
# require "faker"

# # SEEDS FOR ENSEMBLE
# puts "SEEDING STARTS"
# puts "<<<<<Destroying current data>>>>>"
# # destroy work_palns
# WorkPlan.destroy_all
# puts "Workplans destroyed"
# # destroy challenge
# Challenge.destroy_all
# Table.destroy_all
# puts "Challenges and tables destroyed"
# # destroy students
# Student.destroy_all
# puts "Students destroyed"
# # destroy classroom
# SharedClassroom.destroy_all
# Classroom.destroy_all
# puts "SharedClassrrom / Classrooms destroyed"
# # destroy all skills
# Skill.destroy_all
# puts "Skills destroyed"
# # destroy school_roles
# SchoolRole.destroy_all
# puts "SchoolRoles destroyed"
# # destroy all user and school
# User.destroy_all
# puts "Users destroyed"
# School.destroy_all
# puts "Schools destroyed"

# puts "all user and school destroyed"
# puts "=========================================="

# puts "creating school"
# puts ""

# school_ensemble = School.create!(name: "Ensemble", city: "Nantes", email: "school1@mail.com")
# school_fournier = School.create!(name: "Alain Fournier", city: "Nantes", email: "school2@mail.com")

# puts ""
# puts ">>> school created"
# puts "=========================================="
# puts "creating users"
# puts ""

# # create users
# admin = User.create!(email: "admin@mail.com", password: "secret", first_name: "Admin", last_name: "Nimda", admin: true, school: school_ensemble)
# demo = User.create!(email: "demo@mail.com", password: "secret", first_name: "Démo", last_name: "Omde", admin: false, demo: true, school: school_ensemble)
# ensemble_user1 = User.create!(email: "ensemble1@mail.com", password: "secret", first_name: "Benoit", last_name: "Nouille", admin: false, school: school_ensemble)
# fournier_user1 = User.create!(email: "fournier1@mail.com", password: "secret", first_name: "Jean", last_name: "Bon", admin: false, school: school_fournier)
# fournier_user2 = User.create!(email: "fournier2@mail.com", password: "secret", first_name: "Jeanne", last_name: "Bon", admin: false, school: school_fournier)

# puts ""
# puts ">>> users created"
# puts "=========================================="

# puts "creating school_roles"
# puts ""

# SchoolRole.create!(user: admin, school: school_ensemble, super_teacher: true)
# SchoolRole.create!(user: fournier_user1, school: school_fournier, super_teacher: true)

# puts ""
# puts ">>> school_roles created"
# puts "=========================================="

# # "CP" => ["Vocabulaire", "Grammaire", "Numération", "Calcul", "Géométrie", "Grandeurs et Mesures"],
# #     "CE1" => ["Vocabulaire", "Grammaire", "Numération", "Calcul", "Géométrie", "Grandeurs et Mesures"],
# #     "CE2" => ["Conjugaison", "Vocabulaire", "Grammaire", "Numération", "Calcul",
# #               "Géométrie", "Grandeurs et Mesures"],
# #     "CM1" => ["Conjugaison", "Vocabulaire", "Orthographe", "Grammaire", "Poésie", "Géométrie", "Grandeurs et Mesures",
# #               "Numération", "Calcul"],
# #     "CM2"
# puts "=========================================="
# puts "creating grades"
# puts ""
# School.all.each do |school|
#   ["CP","CE1","CE2","CM1","CM2"].each do |grade_level|
#     Grade.create!(grade_level: grade_level, school: school, name: grade_level)
#   end
# end
# puts ""
# puts ">>> grades created"
# # puts "=========================================="
# # puts "creating classrooms"
# # puts ""

# # classroom_ensemble_admin = Classroom.create!(name: "Gpe1", grade: "CE1", user: admin)
# # classroom_ensemble_user1 = Classroom.create!(name: "Gpe2", grade: "CM2", user: ensemble_user1)
# # classroom_alain_fournier_user1 = Classroom.create!(name: "Gpe3", grade: "CE2", user: fournier_user1)
# # classroom_alain_fournier_user2 = Classroom.create!(name: "Gpe4", grade: "CM2", user: fournier_user2)

# # puts ""
# # puts ">>> classrooms created"
# # puts "=========================================="

# # puts "creating students"
# # puts ""

# # Classroom.all.each do |classroom|
# #   puts "creating students for #{classroom.name}"
# #   12.times do
# #     Student.create!(first_name: Faker::Movies::StarWars.character, classroom: classroom)
# #   end
# # end

#UPDATE RESULTS ON LAST wps
classrooms = Classroom.all
classrooms.each do |classroom|

  classroom.grade.domains.each do |domain|
    skills = Skill.where(domain: domain)
    skills.each do |skill|

      classroom.students.each do |student|
        # binding.pry if student.id == 428
        result = Result.find_by(student:, skill:)
        unless result.nil?

          case student.skill_status(skill)
          when "skill_status_completed"
            #skill completed validated resul
             result.update!(kind: "ceinture", status: "completed")
            when "skill_status_belt"
              # skill on belt level => 'new'
               result.update!(kind: "ceinture", status: "new")
            when "kill_status_challenge"
              # skill on challenge = status 'new'
               result.update!(kind: "exercice", status: "new")
          end
      end
      end
      puts "#{skill.name} results updated for #{classroom.name}"
    end
    puts "#{domain.name} results updated for #{classroom.name}"
  end
  puts "END of UPDATING results for #{classroom.name}"
end
