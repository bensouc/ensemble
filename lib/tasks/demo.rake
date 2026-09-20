# frozen_string_literal: true

# Envoyer le mail de bienvenue à un compte de démonstration déjà créé : ceux qui
# se sont inscrits avant que l'envoi automatique n'existe, ou un envoi à refaire.
#
#   rails "demo:bienvenue[prof@ecole.fr]"          # envoie
#   rails "demo:bienvenue[prof@ecole.fr,apercu]"   # n'envoie rien, affiche le mail
namespace :demo do
  desc "Envoie le mail de bienvenue à un compte de démonstration existant"
  task :bienvenue, [:email, :mode] => :environment do |_t, args|
    email = args[:email].to_s.strip
    apercu = args[:mode].to_s.strip == "apercu"

    abort "Usage : rails \"demo:bienvenue[email,(apercu)]\"" if email.blank?

    user = User.find_by(email:)
    abort "Aucun compte avec l'adresse #{email}." if user.nil?
    # Le mail parle de la démo, de ses limites et de l'abonnement à venir : il n'a
    # aucun sens chez un abonné, et le lui envoyer serait une maladresse.
    abort "#{email} n'est pas un compte de démonstration." unless user.demo?

    mail = DemoMailer.bienvenue(user)

    if apercu
      puts mail.subject
      puts "De      : #{mail.from.join(', ')}"
      puts "À       : #{mail.to.join(', ')}"
      puts "-" * 60
      puts mail.body.decoded.dup.force_encoding("UTF-8")
    else
      mail.deliver_now
      puts "Mail de bienvenue envoyé à #{email} (compte créé le #{user.created_at.to_date})."
    end
  end
end
