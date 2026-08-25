# frozen_string_literal: true

# Traduit un événement d'abonnement Stripe en ligne locale.
#
# Les événements sont sérialisés à la version d'API de l'endpoint, réglée dans le
# Dashboard — 2022-11-15 à ce jour, où `quantity`, `current_period_*` et `plan`
# sont à la racine de l'objet. Les versions récentes les ont déplacés sur les
# items : on lit l'item d'abord, la racine ensuite, pour que monter la version
# d'API ne casse rien. (`Stripe.api_version`, qui gouverne les appels sortants,
# n'a aucun effet sur la forme de ce qui arrive ici.)
#
# Tous les accès passent par `[]` : sur un objet Stripe, il renvoie nil pour une
# clé absente, là où l'accesseur lève un NoMethodError.
module Stripesubscription
  RYTHMES = { "year" => "Annuel", "month" => "Mensuel" }.freeze

  # Le nom promettait « create » sans jamais créer : `school.subscription` est nil
  # pour une école qui n'a pas encore d'abonnement, et `nil.update!` levait. C'est
  # la raison pour laquelle le premier abonnement d'une école devait être saisi à
  # la main dans rails_admin.
  def self.update_or_create(event)
    objet = event.data.object
    # L'abonnement d'abord : sur un `updated` — le gros du trafic — l'école n'a
    # plus besoin d'être cherchée.
    abonnement = Subscription.find_by(stripe_subscription_id: objet[:id])
    return abonnement.tap { |a| a.update!(attributs(objet)) } if abonnement

    adopter_ou_creer(objet)
  end

  # Un id inconnu n'est pas une anomalie : Stripe peut annoncer la fin d'un
  # abonnement qui n'a jamais été synchronisé ici.
  def self.delete(stripe_subscription_id)
    Subscription.find_by(stripe_subscription_id:)&.destroy
  end

  def self.adopter_ou_creer(objet)
    school = School.find_by(stripe_customer_id: objet[:customer])
    if school.nil?
      journal("client Stripe inconnu en base", objet)
      return nil
    end

    attrs = attributs(objet)
    return school.subscription.tap { |a| a.update!(attrs) } if school.subscription

    # `current_period_*` sont NOT NULL : sans elles on ne peut pas créer la ligne.
    if attrs[:current_period_start].nil? || attrs[:current_period_end].nil?
      journal("période de facturation absente, création impossible", objet)
      return nil
    end

    school.create_subscription!(attrs)
  end

  def self.attributs(objet)
    item = objet[:items]&.[](:data)&.first
    prix = item&.[](:price) || item&.[](:plan) || objet[:plan]

    { stripe_subscription_id: objet[:id],
      status: objet[:status],
      quantity: lire(item, objet, :quantity),
      cancel_at_period_end: objet[:cancel_at_period_end],
      plan_id: prix&.[](:id),
      rythm: rythme(prix, objet) }.merge(dates(item, objet))
  end

  def self.dates(item, objet)
    { current_period_start: horodatage(lire(item, objet, :current_period_start)),
      current_period_end: horodatage(lire(item, objet, :current_period_end)),
      start_date: horodatage(objet[:start_date]),
      trial_end: horodatage(objet[:trial_end]) }
  end

  # L'item d'abord, la racine ensuite : voir l'en-tête du module.
  def self.lire(item, objet, nom)
    item&.[](nom) || objet[nom]
  end

  # `Time.at(nil)` levait un TypeError : un abonnement sur facture n'a pas de
  # période d'essai, donc `trial_end` y est toujours nul.
  def self.horodatage(valeur)
    valeur && Time.zone.at(valeur)
  end

  # `rythm` n'était jamais renseigné, et le défaut de la base — « annuel » en
  # minuscule — viole la validation du modèle. On le déduit du prix.
  def self.rythme(prix, objet)
    intervalle = prix&.[](:recurring)&.[](:interval) || prix&.[](:interval)
    RYTHMES.fetch(intervalle) do
      journal("intervalle inconnu #{intervalle.inspect}, rythme forcé à Annuel", objet)
      "Annuel"
    end
  end

  def self.journal(message, objet)
    Rails.logger.warn("[stripe] #{message} — abonnement=#{objet[:id]} client=#{objet[:customer]}")
  end

  private_class_method :adopter_ou_creer, :attributs, :dates, :lire, :horodatage,
                       :rythme, :journal
end
