# Aperçu du mail de bienvenue : http://localhost:3000/rails/mailers/demo_mailer
#
# Aucun envoi, aucune écriture en base — le destinataire est un User non
# enregistré, ce qui suffit au gabarit.
class DemoMailerPreview < ActionMailer::Preview
  def bienvenue
    user = User.find_by(demo: true) ||
           User.new(first_name: "Camille", last_name: "Perrin", email: "camille@ecole.fr", demo: true)
    DemoMailer.bienvenue(user)
  end
end
