# frozen_string_literal: true

require "rails_helper"

# Le serveur de développement et la suite de tests envoyaient leurs erreurs sur
# le canal Slack de production (le webhook vient de .env). Hors production,
# rien ne doit partir.
RSpec.describe "Notifications d'erreur" do
  it "ne partent pas hors production" do
    expect(Slack::Notifier).not_to receive(:new)

    expect(ExceptionNotifier.notify_exception(RuntimeError.new("sonde"))).to be(false)
  end
end
