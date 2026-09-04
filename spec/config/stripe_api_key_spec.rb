# frozen_string_literal: true

require "rails_helper"

# Test de dépôt, pas de comportement. `config/initializers/stripe.rb` a déjà été
# entièrement commenté par le passé — c'est pour ça que la clé finissait réglée
# en première ligne de chaque appelant, et qu'une console `rails c` n'en avait
# aucune : le moindre appel tapé à la main levait un AuthenticationError.
RSpec.describe "Clé API Stripe" do
  let(:assignations) do
    Rails.root.join("config/initializers/stripe.rb").readlines.grep(/^\s*Stripe\.api_key\s*=/)
  end

  it "est posée au démarrage, hors commentaire" do
    expect(assignations).not_to be_empty,
                               "config/initializers/stripe.rb ne pose plus Stripe.api_key : " \
                               "tout chemin qui ne la règle pas lui-même partira sans clé."
  end

  it "la lit dans l'environnement, jamais en dur" do
    expect(assignations).to all(include("ENV"))
    expect(assignations.join).not_to match(/sk_(test|live)_/)
  end
end
