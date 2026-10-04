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

    # Une clé absente, une clé refusée, une allocation consommée : aucune de
    # ces trois-là ne se répare en réessayant, et les relancer cinq fois ne
    # ferait qu'encombrer les jobs en échec — ou, pour la dernière, cogner
    # cinq fois contre un plafond de requêtes. `Quota` hérite d'`Indisponible`
    # et tombe donc ici aussi. Déclaré après le `retry_on` d'ApplicationJob,
    # il passe avant lui.
    discard_on Synthese::Indisponible

    def perform(probleme)
      # Un problème retiré de la circulation entre-temps : personne ne l'écoute.
      return unless probleme.published?
      return unless Synthese.disponible?

      GenerationAudio.new.traiter_probleme(probleme)
    end
  end
end
