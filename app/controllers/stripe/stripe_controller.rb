# frozen_string_literal: true

# Le portail de facturation Stripe : c'est de là que le responsable d'une école
# change sa quantité de classes, sa carte, ou résilie.
class Stripe::StripeController < ApplicationController
  # Le portail exige un client Stripe qui existe encore. Un `stripe_customer_id`
  # en base n'en est pas la preuve : un client supprimé depuis le Dashboard laisse
  # son id derrière lui, et l'ouverture du portail échoue en 400
  # `resource_missing`. L'école récoltait une 500, sans un mot sur ce qu'elle
  # devait faire.
  #
  # On ne vérifie pas le client avant l'appel : ce serait un appel réseau de plus
  # à chaque ouverture pour un cas rare — et `Customer.retrieve` ne suffirait même
  # pas à trancher, un client supprimé s'y lisant en 200 (voir `StripeHelper`).
  # On lit l'échec, qui dit exactement de quoi il s'agit.
  #
  # L'autorisation passe avant l'appel à Stripe : sinon un utilisateur non
  # autorisé faisait travailler l'API avant de se voir refuser.
  def create_portal_session
    authorize Stripe::BillingPortal::Session.new
    # Posée ici en plus de l'initializer : `Stripe.api_key` est global au
    # processus, et ce fichier d'initializer a déjà été entièrement commenté par
    # le passé. Sans elle, un worker Puma neuf — où aucun appel n'est encore
    # passé par `StripeHelper` — part sans clé et lève un AuthenticationError.
    Stripe.api_key = ENV.fetch("STRIPE_API_KEY", nil)

    school = current_user.school
    return orienter(school, "aucun client Stripe en base") if school.stripe_customer_id.blank?

    redirect_to ouvrir_portail(school.stripe_customer_id).url, allow_other_host: true
  rescue Stripe::InvalidRequestError => e
    # `resource_missing` ne peut désigner que le client : c'est la seule ressource
    # que cet appel nomme. Tout autre échec — le portail non configuré dans le
    # Dashboard, par exemple — est une surprise, et doit remonter pour être
    # notifié plutôt que d'être avalé en message d'interface.
    raise unless e.code == "resource_missing"

    orienter(school, e.message)
  end

  private

  def ouvrir_portail(customer)
    Stripe::BillingPortal::Session.create({
                                            customer:,
                                            locale: "fr",
                                            return_url: "#{ApplicationHelper.default_url_options[:host]}/dashboard"
                                          })
  end

  # Répare l'id au passage : c'est lui qui permet de rattacher l'abonnement
  # depuis le Dashboard, sans une intervention en console de plus. Le client neuf
  # est vide — ni abonnement ni facture : ouvrir le portail dessus dirait à
  # l'école que tout va bien.
  #
  # Une école sans abonnement peut souscrire elle-même. Une école qui en a un
  # sans exister chez Stripe — celui réglé par virement, saisi à la main dans
  # `/admin` — ne peut rien y faire : c'est à nous de le rattacher.
  def orienter(school, raison)
    perime = school.stripe_customer_id
    StripeHelper.get_or_create_customer(school)
    Rails.logger.warn("[stripe] portail impossible — école=#{school.id} client périmé=#{perime.inspect} " \
                      "client neuf=#{school.stripe_customer_id} — #{raison}")

    if school.subscription.nil?
      return redirect_to new_subscription_path,
                         alert: "Souscrivez un abonnement pour accéder au portail de facturation."
    end

    redirect_back fallback_location: dashboard_path,
                  alert: "Votre abonnement n'est pas géré depuis Stripe : le portail de facturation n'a rien à " \
                         "vous afficher. Écrivez-nous, nous le rattachons."
  end
end
