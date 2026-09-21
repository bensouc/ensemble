# frozen_string_literal: true

# Le premier message reçu par un enseignant qui vient d'ouvrir un compte de
# démonstration : ce qu'est Ensemble, par où commencer, ce que la démo permet et
# ce qu'elle ne permet pas, et ce qui l'attend s'il s'abonne.
#
# `ContactMailer#new_demo_user` prévient l'équipe de la même inscription ; celui-ci
# s'adresse à l'enseignant, et c'est la seule différence qui compte : tout ce qui
# est écrit ici sera lu par un client.
class DemoMailer < ApplicationMailer
  # `bensoucdev@gmail.com` — le `default from:` d'ApplicationMailer — convient aux
  # notifications internes, pas à un envoi vers l'extérieur. On reprend
  # l'expéditeur des courriels Devise : c'est le domaine de l'application, et le
  # seul dont les enregistrements DNS répondent (voir config/initializers/devise.rb).
  default from: "Ensemble <#{Devise.mailer_sender}>"

  def bienvenue(user)
    @user = user
    @prenom = user.first_name&.strip.presence&.capitalize
    # « le mot de passe que vous venez de choisir » ne vaut que le jour de
    # l'inscription. `demo:bienvenue` sert aussi à rattraper des comptes ouverts
    # depuis des semaines : leur demander de se souvenir d'un mot de passe choisi
    # il y a longtemps, sans rien leur proposer d'autre, est une impasse.
    #
    # `created_at` est nul sur un utilisateur non enregistré — l'aperçu du
    # gabarit — et c'est bien le mail d'inscription qu'il faut y montrer.
    @inscription_du_jour = user.created_at.nil? || user.created_at > 1.day.ago
    mail(to: user.email, subject: "Bienvenue sur Ensemble — votre compte de démonstration est ouvert")
  end
end
