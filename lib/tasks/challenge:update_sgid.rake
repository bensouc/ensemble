require "global_id"

namespace :challenge do
  desc "Sweeping unused empty challenges"
  task update_sgid: :environment do
    # script/regenerate_sgids.rb

    # Assurez-vous que vous avez configuré Rails pour utiliser la nouvelle clé
    # Rails.application.config.secret_key_base = ENV["SECRET_KEY_BASE"]

    # Parcourez tous les challenges et regénérez les SGIDs pour les attachements d'Action Text
    Challenge.find_each do |challenge|
      challenge.content.body.attachments.each do |attachment|
        if attachment.attachable.is_a?(ActiveStorage::Blob)
          new_sgid = attachment.attachable.to_sgid.to_s
          attachment.update(sgid: new_sgid)
        end
      end
    end
  end
end
