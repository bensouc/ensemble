# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  # Sidekiq relançait d'office tout job en échec, 25 fois sur plusieurs jours.
  # Solid Queue ne relance rien : un échec part directement dans les jobs en
  # échec de /jobs. On garde une relance bornée pour les pannes passagères (un
  # Chrome qui ne répond pas, un SMTP qui coupe) : 5 essais en 6 minutes environ.
  retry_on StandardError, wait: :polynomially_longer, attempts: 5

  # L'enregistrement a disparu (une classe supprimée entre-temps) : relancer n'y
  # changera rien. Déclaré après `retry_on`, il passe avant lui.
  discard_on ActiveJob::DeserializationError
end
