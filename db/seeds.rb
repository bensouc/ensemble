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
demo = User.create!(email: "demo@mail.com", password: "secret", first_name: "Démo", last_name: "Omde", admin: false, demo: true, school: school_ensemble)
ensemble_user1 = User.create!(email: "ensemble1@mail.com", password: "secret", first_name: "Benoit", last_name: "Nouille", admin: false, school: school_ensemble)
fournier_user1 = User.create!(email: "fournier1@mail.com", password: "secret", first_name: "Jean", last_name: "Bon", admin: false, school: school_fournier)
fournier_user2 = User.create!(email: "fournier2@mail.com", password: "secret", first_name: "Jeanne", last_name: "Bon", admin: false, school: school_fournier)

puts ""
puts ">>> users created"
puts "=========================================="

puts "creating school_roles"
puts ""

SchoolRole.create!(user: admin, school: school_ensemble, super_teacher: true)
SchoolRole.create!(user: fournier_user1, school: school_fournier, super_teacher: true)

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
# end



# [1774,
#  1780,
#  1784,
#  1787,
#  1798,
#  1800,
#  1804,
#  1810,
#  1815,
#  1819,
#  1903,
#  1910,
#  1912,
#  1918,
#  1919,
#  1921,
#  1922,
#  1924,
#  1927,
#  1928,
#  1929,
#  1930,
#  1931,
#  1933,
#  1935,
#  1936,
#  1937,
#  1938,
#  1939,
#  1940,
#  1942,
#  1943,
#  1944,
#  1945,
#  1946,
#  1948,
#  1964,
#  1977,
#  1984].each do |skill_id|
#   skill = Skill.find(skill_id)
#   domain = Domain.find_by(grade: Grade.find(10), name: skill.name_domain)
#   p skill.update!(domain: domain)
#  end

#  [
#   3836,
# 3839,
# 3842,
# 3851,
# 3852,
# 3856,
# 3861,
# 3866,
# 3869,
# 3949,
# 3954,
# 3955,
# 3957,
# 3958,
# 3960,
# 3962,
# 3963,
# 3964,
# 3965,
# 3966,
# 3969,
# 3970,
# 3971,
# 3972,
# 3973,
# 3974,
# 3975,
# 3976,
# 3977,
# 3978,
# 3979,
# 3981,
# 3988,
# 4011,
# 4018,
# 4150,
# 4167,
# 4169,
# 4172,
# 4176
#  ].each do |skill_id|
#   skill = Skill.find(skill_id)
#   domain = Domain.find_by(grade: Grade.find(5), name: skill.name_domain)
#   p skill.update!(domain: domain)
#  end
