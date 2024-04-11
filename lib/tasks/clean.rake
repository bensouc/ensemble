# lib/tasks/clean.rake

namespace :clean do
  desc "Sweeping unused empty challenges"
  task empty_challenges: :environment do
    puts "############################"
    puts "###                      ###"
    puts "###      Challenges      ###"
    puts "###   SWEEPING STARTS    ###"
    puts "###                      ###"
    puts "############################"
    # TODO: Ajoutez votre logique de tâche ici
    # get all empty challenges without any workdplanskills
    empty_chall = Challenge.new
    empty_chall.content.body = <<~HTML
      Exercice à REDIGER............................
    HTML
    empty_challenges = Challenge.all.select { |c| c.content.body == empty_chall.content.body && c.work_plan_skills.empty? }
    empty_challenges.each do |c|
      c.destroy
      puts "Challenge ID #{c.id} has been destroyed"
    end

    puts "#{empty_challenges.count} challenges have been destroyed"

    puts "############################"
    puts "###                      ###"
    puts "###      Challenges      ###"
    puts "###    SWEEPING DONE     ###"
    puts "###                      ###"
    puts "############################"
  end
end
