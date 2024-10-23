namespace :challenge do
  desc "Cleaning Challenge attachment with"
  task update_lt_to_fr: :environment do
    # script/regenerate_sgids.rb

    # Assurez-vous que vous avez configuré Rails pour utiliser la nouvelle clé
    # Rails.application.config.secret_key_base = ENV["SECRET_KEY_BASE"]

    # Parcourez tous les challenges et regénérez les SGIDs pour les attachements d'Action Text
    Challenge.find_each do |challenge|
      if challenge.content.body.to_s.include?("ensemble.lt")
        updated_content = challenge.content.body.to_s.gsub("ensemble.lt", "app-ensemble.fr")
        challenge.content.body = updated_content
        challenge.save!
        puts "Challenge #{challenge.id} updated for ensemble.lt"
      elsif challenge.content.body.to_s.include?("ensemble-v1.herokuapp.com")
        updated_content = challenge.content.body.to_s.gsub("ensemble-v1.herokuapp.com", "www.app-ensemble.fr")
        challenge.content.body = updated_content
        challenge.save!
        puts "Challenge #{challenge.id} updated for ensemble-v1.herokuapp.com"
      end

    end
  end
end
