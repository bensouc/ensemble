require "open-uri"
require "faker"

# SEEDS FOR ENSEMBLE
puts "SEEDING STARTS"
puts "<<<<<Destroying current data>>>>>"
# destroy work_palns
WorkPlan.destroy_all
puts "Workplans destroyed"
# destroy challenge
Challenge.destroy_all
Table.destroy_all
puts "Challenges and tables destroyed"
# destroy students
Student.destroy_all
puts "Students destroyed"
# destroy classroom
SharedClassroom.destroy_all
Classroom.destroy_all
puts "SharedClassrrom / Classrooms destroyed"
# destroy all skills
Skill.destroy_all
puts "Skills destroyed"
# destroy school_roles
SchoolRole.destroy_all
puts "SchoolRoles destroyed"
# destroy all user and school
User.destroy_all
puts "Users destroyed"
School.destroy_all
puts "Schools destroyed"

puts "all user and school destroyed"
puts "=========================================="

puts "creating school"
puts ""

school_ensemble = School.create!(name: "Ensemble", city: "Nantes", email: "school1@mail.com")
school_fournier = School.create!(name: "Alain Fournier", city: "Nantes", email: "school2@mail.com")

puts ""
puts ">>> school created"
puts "=========================================="
puts "creating users"
puts ""

# create users
admin = User.create!(email: "admin@mail.com", password: "secret", first_name: "Admin", last_name: "Nimda", admin: true, school: school_ensemble)
ensemble_user1 = User.create!(email: "ensemble1@mail.com", password: "secret", first_name: "Benoit", last_name: "Nouille", admin: false, school: school_ensemble)
fournier_user1 = User.create!(email: "fournier1@mail.com", password: "secret", first_name: "Jean", last_name: "Bon", admin: false, school: school_fournier)
fournier_user2 = User.create!(email: "fournier2@mail.com", password: "secret", first_name: "Jeanne", last_name: "Bon", admin: false, school: school_fournier)

puts ""
puts ">>> users created"
puts "=========================================="

puts "creating school_roles"
puts ""

SchoolRole.create!(user: admin, school: school_ensemble)
SchoolRole.create!(user: fournier_user1, school: school_fournier)

puts ""
puts ">>> school_roles created"
puts "=========================================="


# "CP" => ["Vocabulaire", "Grammaire", "Numération", "Calcul", "Géométrie", "Grandeurs et Mesures"],
#     "CE1" => ["Vocabulaire", "Grammaire", "Numération", "Calcul", "Géométrie", "Grandeurs et Mesures"],
#     "CE2" => ["Conjugaison", "Vocabulaire", "Grammaire", "Numération", "Calcul",
#               "Géométrie", "Grandeurs et Mesures"],
#     "CM1" => ["Conjugaison", "Vocabulaire", "Orthographe", "Grammaire", "Poésie", "Géométrie", "Grandeurs et Mesures",
#               "Numération", "Calcul"],
#     "CM2"
puts "=========================================="
puts "creating grades"
puts ""
School.all.each do |school|
  ["CP","CE1","CE2","CM1","CM2"].each do |grade_level|
    Grade.create!(grade_level: grade_level, school: school, name: grade_level)
  end
end
puts ""
puts ">>> grades created"
# puts "=========================================="
# puts "creating classrooms"
# puts ""

# classroom_ensemble_admin = Classroom.create!(name: "Gpe1", grade: "CE1", user: admin)
# classroom_ensemble_user1 = Classroom.create!(name: "Gpe2", grade: "CM2", user: ensemble_user1)
# classroom_alain_fournier_user1 = Classroom.create!(name: "Gpe3", grade: "CE2", user: fournier_user1)
# classroom_alain_fournier_user2 = Classroom.create!(name: "Gpe4", grade: "CM2", user: fournier_user2)

# puts ""
# puts ">>> classrooms created"
# puts "=========================================="

# puts "creating students"
# puts ""

# Classroom.all.each do |classroom|
#   puts "creating students for #{classroom.name}"
#   12.times do
#     Student.create!(first_name: Faker::Movies::StarWars.character, classroom: classroom)
#   end
#   puts ">>> students created  for #{classroom.name}"
# end

# puts ""
# puts ">>> students created"
# puts "=========================================="

# puts "creating shared classrooms"
# puts ""

# SharedClassroom.create!(user: ensemble_user1, classroom: classroom_ensemble_admin)
# SharedClassroom.create!(user: fournier_user1, classroom: classroom_alain_fournier_user2)

# puts ""
# puts ">>> shared classrooms created"


puts "=========================================="

puts "creating skills"
puts ""

# "CE1" => ["Vocabulaire", "Grammaire", "Numération", "Calcul", "Géométrie", "Grandeurs et Mesures"]
School.all.each do |school|
  puts "creating skills for #{school.name}"
  WorkPlanDomain::DOMAINS.each do |grade, domains|
    domains.each do |domain|
      p final_grade = Grade.find_by(school: , grade_level: grade)
      if domain.in?(WorkPlanDomain::DOMAINS_SPECIALS) && school == school_fournier
        15.times do
          Skill.create!(school:, domain:, level: 1, symbol: "⬥", name: Faker::Movies::StarWars.quote, grade: final_grade)
        end
      else
        for i in (1..7)
          2.times do
            Skill.create!(school:, domain:, level: i, symbol: "⬥", name: Faker::Movies::StarWars.quote, grade: final_grade)
          end
        end
      end
    end
  end
  puts "skills created  for #{school.name}"
end
puts ""
puts ">>> skills created"
puts "=========================================="
puts "==============SEED COMPLETED=============="
