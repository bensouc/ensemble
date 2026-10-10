class ApplicationMailer < ActionMailer::Base
  # L'adresse du domaine de l'application, celle des courriels Devise : c'est le
  # seul expéditeur que Brevo signe. `bensoucdev@gmail.com` partait vers les
  # enseignants (résultats d'une classe, confirmation d'un changement
  # d'abonnement) au nom d'un domaine que nous ne signons pas.
  default from: "Ensemble <#{Devise.mailer_sender}>"
  layout "mailer"
  helper MailStylesHelper
end
