# frozen_string_literal: true

module Manipule
  # Fabrique l'audio d'un problème mis en circulation.
  #
  # Posté à la validation, et à chaque fois qu'un texte déjà en circulation
  # change. Le travail est sélectif : chaque partie — l'énoncé, la question,
  # chaque réponse — n'est refaite que si son texte a bougé. Corriger un mot
  # d'énoncé ne refabrique pas les trois réponses.
  class GenererAudioJob < ApplicationJob
    queue_as :default

    # Le serveur de production n'a pas `say` tant que l'adaptateur distant
    # n'est pas écrit : relancer cinq fois un job qui ne peut pas aboutir ne
    # ferait qu'encombrer les jobs en échec. Déclaré après le `retry_on`
    # d'ApplicationJob, il passe avant lui.
    discard_on Synthese::Indisponible

    def perform(probleme)
      # Un problème retiré de la circulation entre-temps : personne ne l'écoute.
      return unless probleme.published?
      return unless Synthese.disponible?

      GenerationAudio.new.traiter_probleme(probleme)
    end
  end
end
