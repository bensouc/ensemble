# frozen_string_literal: true

# Charger une charge utile Stripe réelle : `Stripe::Event.construct_from` sur du
# JSON aux clés symbolisées est l'incantation qu'on ne veut écrire qu'une fois.
module StripeFixtures
  def evenement_stripe(nom)
    chemin = Rails.root.join("spec/fixtures/stripe/#{nom}.json")
    Stripe::Event.construct_from(JSON.parse(chemin.read).deep_symbolize_keys)
  end
end

RSpec.configure { |config| config.include StripeFixtures }
