# frozen_string_literal: true

# Traduit un événement d'abonnement Stripe en ligne locale.
#
# Les événements arrivent sérialisés à la version d'API du compte — 2022-11-15 à
# ce jour — où `quantity`, `current_period_*` et `plan` sont à la racine de
# l'objet. Les versions récentes les ont déplacés sur les items : les lectures
# ci-dessous regardent l'item d'abord et retombent sur la racine, pour que
# monter la version d'API ne casse rien.
module Stripesubscription
  RYTHMES = { "year" => "Annuel", "month" => "Mensuel" }.freeze

  # Le nom promettait « create » sans jamais créer : `school.subscription` est nil
  # pour une école qui n'a pas encore d'abonnement, et `nil.update!` levait. C'est
  # la raison pour laquelle le premier abonnement d'une école devait être saisi à
  # la main dans rails_admin.
  def self.update_or_create(event)
    objet = event.data.object
    school = School.find_by(stripe_customer_id: objet.customer)
    if school.nil?
      journal("client Stripe inconnu en base", objet)
      return nil
    end

    abonnement = Subscription.find_by(stripe_subscription_id: objet.id) || school.subscription
    enregistrer(school, abonnement, objet)
  end

  # Un id inconnu n'est pas une anomalie : Stripe peut annoncer la fin d'un
  # abonnement qui n'a jamais été synchronisé ici.
  def self.delete(stripe_subscription_id)
    Subscription.find_by(stripe_subscription_id:)&.destroy
  end

  def self.enregistrer(school, abonnement, objet)
    attrs = attributs(objet)
    return abonnement.tap { |a| a.update!(attrs) } if abonnement

    # `current_period_*` sont NOT NULL : sans elles on ne peut pas créer la ligne.
    if attrs[:current_period_start].nil? || attrs[:current_period_end].nil?
      journal("période de facturation absente, création impossible", objet)
      return nil
    end

    school.create_subscription!(attrs)
  end

  def self.attributs(objet)
    item = objet.items&.data&.first

    { stripe_subscription_id: objet.id,
      status: objet.status,
      quantity: lire(item, objet, :quantity),
      cancel_at_period_end: objet.cancel_at_period_end,
      plan_id: plan_id(item, objet),
      rythm: rythme(item, objet) }.merge(dates(item, objet))
  end

  def self.dates(item, objet)
    { current_period_start: horodatage(lire(item, objet, :current_period_start)),
      current_period_end: horodatage(lire(item, objet, :current_period_end)),
      start_date: horodatage(champ(objet, :start_date)),
      trial_end: horodatage(champ(objet, :trial_end)) }
  end

  # `Time.at(nil)` levait un TypeError : un abonnement sur facture n'a pas de
  # période d'essai, donc `trial_end` y est toujours nul.
  def self.horodatage(valeur)
    valeur && Time.zone.at(valeur)
  end

  # L'item d'abord, la racine ensuite : voir l'en-tête du module.
  def self.lire(item, objet, nom)
    champ(item, nom) || champ(objet, nom)
  end

  # Les objets Stripe lèvent un NoMethodError sur un champ absent de la charge
  # utile, au lieu de renvoyer nil.
  def self.champ(objet, nom)
    objet.respond_to?(nom) ? objet.public_send(nom) : nil
  rescue NoMethodError
    nil
  end

  def self.plan_id(item, objet)
    champ(item&.price, :id) || champ(item&.plan, :id) || champ(champ(objet, :plan), :id)
  end

  # `rythm` n'était jamais renseigné, et le défaut de la base — « annuel » en
  # minuscule — viole la validation du modèle. On le déduit du prix.
  def self.rythme(item, objet)
    intervalle = champ(champ(item&.price, :recurring), :interval) ||
                 champ(champ(objet, :plan), :interval)
    RYTHMES.fetch(intervalle) do
      journal("intervalle inconnu #{intervalle.inspect}, rythme forcé à Annuel", objet)
      "Annuel"
    end
  end

  def self.journal(message, objet)
    Rails.logger.warn("[stripe] #{message} — abonnement=#{objet.id} client=#{objet.customer}")
  end

  private_class_method :enregistrer, :attributs, :dates, :horodatage, :lire, :champ,
                       :plan_id, :rythme, :journal
end
