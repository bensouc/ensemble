# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Notifications d'erreur" do
  # Le serveur de développement et la suite de tests envoyaient leurs erreurs sur
  # le canal Slack de production (le webhook vient de .env). Hors production,
  # rien ne doit partir.
  it "ne partent pas hors production" do
    expect(Slack::Notifier).not_to receive(:new)

    expect(ExceptionNotifier.notify_exception(RuntimeError.new("sonde"))).to be(false)
  end

  describe "en production" do
    let(:notifieurs) { ExceptionNotifier.notifiers.map { |nom| ExceptionNotifier.registered_exception_notifier(nom) } }

    before do
      allow(Rails.env).to receive(:production?).and_return(true)
      notifieurs.each { |notifieur| allow(notifieur).to receive(:call) }
    end

    it "préviennent d'une vraie erreur" do
      ExceptionNotifier.notify_exception(RuntimeError.new("sonde"))

      expect(notifieurs).to all(have_received(:call))
    end

    # `params.expect` répond 400 à un paramètre mal formé (#523) : c'est une
    # faute du client — robot, requête bricolée —, pas un bug de l'appli.
    it "taisent un paramètre mal formé" do
      ExceptionNotifier.notify_exception(ActionController::ParameterMissing.new(:work_plan))

      notifieurs.each { |notifieur| expect(notifieur).not_to have_received(:call) }
    end
  end
end
