# frozen_string_literal: true

# Point d'entrée des événements Stripe. Public par nature : c'est la signature
# de la charge utile qui authentifie l'appel, pas une session.
module Stripe
  class StripeWebhooksController < ApplicationController
    skip_before_action :authenticate_user!
    # `raise: false` parce que le rappel n'existe pas encore : `config.load_defaults`
    # n'est jamais appelé, donc `protect_from_forgery` n'est pas installé et
    # `skip_before_action` lèverait. Le jour où il le sera, tous les webhooks
    # tomberaient — et exception_notification ignore justement
    # InvalidAuthenticityToken, la panne serait silencieuse.
    skip_before_action :verify_authenticity_token, raise: false

    def create
      skip_authorization
      event = evenement_signe
      return if performed?

      traiter(event)
      render json: { message: "success" }
    end

    private

    def evenement_signe
      Stripe::Webhook.construct_event(request.body.read, request.env["HTTP_STRIPE_SIGNATURE"],
                                      ENV.fetch("STRIPE_WEBHOOK_SECRET_KEY", nil))
    rescue JSON::ParserError, Stripe::SignatureVerificationError => e
      # `status 400` puis `return` ne rendait pas de 400 : `status` a une arité de
      # zéro sur ce contrôleur, et l'absence de rendu finissait en 500 — que Stripe
      # rejoue trois jours durant, sans espoir.
      Rails.logger.warn("[stripe] charge utile refusée — #{e.class}")
      head :bad_request
      nil
    end

    # Une charge utile qu'on ne sait pas traiter ne doit pas déclencher trois jours
    # de rejeux : on journalise et on acquitte. Les erreurs transitoires, elles,
    # doivent remonter — d'où le `raise` sur les erreurs de base de données.
    def traiter(event)
      case event.type
      when "customer.updated"      then Stripecustomer.update_stripe_customer(event)
      when "customer.deleted"      then Stripecustomer.remove_stripe_customer(event)
      when "customer.subscription.created", "customer.subscription.updated"
        Stripesubscription.update_or_create(event)
      when "customer.subscription.deleted"
        Stripesubscription.delete(event.data.object.id)
      end
      Rails.logger.info("[stripe] #{event.type} traité — #{event.id}")
    rescue ActiveRecord::ActiveRecordError
      raise
    rescue StandardError => e
      Rails.logger.error("[stripe] #{event.type} (#{event.id}) — #{e.class}: #{e.message}")
    end
  end
end
