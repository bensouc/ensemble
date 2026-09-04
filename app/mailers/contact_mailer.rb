class ContactMailer < ApplicationMailer
  # `classes_label` fléchit « classe » en français, ce que `pluralize` ne fait
  # pas : aucune inflexion n'est définie pour cette locale.
  helper ClassroomsHelper

  def new_contact(contact)
    @contact = contact
    mail(to: "bensoucdev@gmail.com", subject: "Nouveau contact")
  end

  def new_demo_user(contact)
    @contact = contact
    mail(to: "bensoucdev@gmail.com", subject: "Nouveau Compte Démo")
  end

  def new_request(user_request)
    @user_request = user_request
    mail(to: "bensoucdev@gmail.com", subject: "Nouvelle demande")
  end

  # Le nom de l'école dans l'objet : ces demandes s'agissent une par une dans le
  # Dashboard Stripe, et le mail sert de fil de suivi.
  def subscription_change_request(demande)
    @demande = demande
    mail(to: "bensoucdev@gmail.com",
         subject: "Modification d'abonnement — #{demande[:school].name}")
  end

  # L'accusé de réception, à l'école. Il nomme l'adresse à laquelle partira la
  # facture : c'est celle du client Stripe, tirée de `schools.email`, et elle est
  # souvent personnelle là où le service comptable attend la facture ailleurs.
  # La nommer donne à l'école l'occasion de la corriger avant l'émission.
  #
  # Le demandeur ET l'école : le premier a rempli le formulaire et attend une
  # réponse, la seconde est l'adresse de facturation. Souvent la même.
  def subscription_change_confirmation(demande)
    @demande = demande
    @document = document_de_facturation(demande)
    mail(to: [demande[:demandeur].email, demande[:facturation_email]].compact_blank.uniq,
         subject: "Votre demande de modification d'abonnement")
  end

  private

  # Une hausse de quantité fait émettre une facture de prorata par Stripe, une
  # baisse un avoir : promettre « une facture » dans les deux sens était faux
  # pour une école qui réduit son nombre de classes.
  #
  # À quantité égale — le responsable nous écrit sans rien changer, pour poser une
  # question dans le champ libre — il n'y a ni l'un ni l'autre, et rien à annoncer.
  def document_de_facturation(demande)
    case demande[:quantite_apres].to_i <=> demande[:quantite_avant].to_i
    when 1 then :facture
    when -1 then :avoir
    else :aucun
    end
  end

  # def contact_params
  #   params.require(:contact).permit(:nom, :email, :school, :city, :message)
  # end
end
