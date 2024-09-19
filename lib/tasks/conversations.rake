namespace :conversations do
  desc "Update school user conversations"
  task school_update: :environment do
    puts "############################"
    puts "###                      ###"
    puts "###       results        ###"
    puts "###    UPDATE SCHOOL     ###"
    puts "###                      ###"
    puts "############################"
    School.all.each do |school|
      teachers = school.users
      school_conversation = Conversation.find_or_create_school_conversation(teachers.first)
      teachers.each do |teacher|
        unless school_conversation.users.include?(teacher)
          puts "Add #{teacher.email} to #{school_conversation.name}"
          school_conversation.users << teacher
        end
      end
    end
  end
end
