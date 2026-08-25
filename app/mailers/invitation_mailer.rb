# frozen_string_literal: true

# Devise envoie « Vous avez reçu une invitation » : le destinataire n'attend pas
# ce message et l'objet ne lui dit ni de qui il vient, ni pour quoi. On le nomme.
#
# Sous-classe de Devise::Mailer : tous les autres envois (mot de passe oublié,
# confirmation) passent par ici sans changer de comportement ni de gabarit.
class InvitationMailer < Devise::Mailer
  # Devise::Mailer ne reprend pas le gabarit applicatif : chaque vue recopiait sa
  # propre coquille (logo, titre), et elles avaient divergé.
  layout "mailer"
  helper MailStylesHelper
  def invitation_instructions(record, token, opts = {})
    school = record.school
    opts[:subject] = if school
                       "Ensemble : vous êtes invité(e) à rejoindre #{school.name.capitalize}"
                     else
                       "Ensemble : vous êtes invité(e) à rejoindre un groupe"
                     end
    super
  end
end
