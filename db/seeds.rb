# puts "ADD school id = 17 to all skills"
# skills = Skill.all
# school = School.find(1)
# skills.each do |skill|
#   skill.school = school
#   skill.save!
# end
# puts "END of Adding school id = 17 to all skills"
# get all skill where school_id = 1
# destroy all skill where school_id = 18
# destroy all work_plan where work_plan.user.school_id = 18
puts "destroy all work_plan where school_id = 18"
WorkPlan.where(user_id: User.where(school_id: 18).ids).destroy_all

puts "destroy all skills where school_id = 18"
Skill.where(school_id: 18).destroy_all

puts "create new skills and exos"

original_skills = Skill.where(school_id: 17) #1 in prod
user_school_ensemble = User.where(school_id: 18).first #2 in prod
original_skills.each do |original_skill|
  new_skill = original_skill.dup
  new_skill.school_id = 18 # 2 in prod
  new_skill.save!
  puts "new skill created #{new_skill.id}"
  # get all exos where skill_id = original_skill.id
  exos = Challenge.where(skill_id: original_skill.id)
  exo = exos.last unless exos.empty?
  unless exo.nil?
    new_exo = exo.new_clone
    new_exo.user = user_school_ensemble
    new_exo.skill_id = new_skill.id
    new_exo.save!
    puts "new exo created #{new_exo.id}"
  end
end

# pour chaques skills créer un skill_school where school_id = 2 (ensemble)
# pour chaques skills recupere un exo hazard et le dupliquer puis l'asigner à la nouvelle skill
