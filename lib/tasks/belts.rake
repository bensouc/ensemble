namespace :belts do
  desc "Sweeping unused empty challenges"
  task clean_double: :environment do
    puts "############################"
    puts "###                      ###"
    puts "###      Belts           ###"
    puts "###    CLEAN DOUBLE      ###"
    puts "###                      ###"
    puts "############################"
    count = 0
    Student.all.each do |student|
      student.belts.sort_by(&:updated_at).each do |belt|
        if student.belts.where(domain: belt.domain, level: belt.level).count > 1
          belt.destroy
          puts "Belt ID #{belt.id} has been destroyed"
          count += 1
        end
      end
    end
    puts "#{count} belts have been destroyed"
    puts "############################"
  end
end
