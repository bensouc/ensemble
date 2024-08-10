namespace :result do
  desc "Update Result based on last updated wps"
  task update: :environment do
    puts "############################"
    puts "###                      ###"
    puts "###       results        ###"
    puts "###       UPDATE         ###"
    puts "###                      ###"
    puts "############################"
    puts "What is your classroom ID"
    classroom_id = gets.chomp.to_i
    update_results_for_a_classroom(classroom_id)
  end

  desc "Update Result based on last updated wps"
  task update_all: :environment do
    puts "############################"
    puts "###       UPDATE         ###"
    puts "###      Results         ###"
    puts "###   4 all Classrooms   ###"
    puts "############################"
    Classroom.all.each {|c| update_results_for_all_classroom(c.id)}
  end

  def update_results_for_all_classroom(classroom_id)
    classroom = Classroom.find(classroom_id)
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
