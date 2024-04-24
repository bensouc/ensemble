namespace :result do
  desc "Update Result based on last updated wps"
  puts "############################"
  puts "###                      ###"
  puts "###        results       ###"
  puts "###       UPDATESS       ###"
  puts "###                      ###"
  puts "############################"
  task update: :environment do
    puts "What is your classroom ID"
    classroom = Classroom.find(gets.chomp.to_i)
    p classroom
    students = classroom.students
    domains = classroom.grade.domains
    domains.each do |domain|
      skills = domain.skills
      students.each do |student|
        skills.each do |skill|
          next if student.work_plan_skills.where(skill:).empty?
          # get result for skills and students
          result = Result.find_by(student:, skill:)
          # update result
          # binding.pry
          next if result.nil?
          status = student.skill_status(skill)
          case status
          when "skill_status_completed"
            # kind: "ceinture", status: "completed"
             result.update(kind: "ceinture", status: "completed")
             p result
          when "skill_status_belt"
            # kind: "exercice", status: completed
             result.update(kind: "exercice", status: "completed")
             p result
          when "skill_status_challenge"
             result.update(kind: "exercice", status: "new")
             p result
            # kind: "exercice",status: "new"
          end
        end
      end
    end
  end
end
