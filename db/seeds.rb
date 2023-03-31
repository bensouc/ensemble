puts "ADD school id = 17 to all skills"
skills = Skill.all
school = School.find(1)
skills.each do |skill|
  skill.school = school
  skill.save!
end
puts "END of Adding school id = 17 to all skills"
