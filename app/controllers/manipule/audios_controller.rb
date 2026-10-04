# frozen_string_literal: true

module Manipule
  # Sert un morceau d'audio pré-généré.
  #
  # Ouvert à l'élève en séance comme à l'enseignante connectée : la première en
  # a besoin pour écouter, la seconde pour relire sa banque avant de la mettre
  # en circulation. Personne d'autre.
  class AudiosController < EleveController
    def show
      return head(:forbidden) unless eleve_courant || user_signed_in?

      audio = Audio.find(params[:id])
      # Un morceau ne change pas tant que son texte ne change pas, et une
      # réécoute est précisément ce qu'on attend de l'élève : autant que le
      # navigateur le garde plutôt que de repartir sur le réseau à chaque fois.
      expires_in 1.week, public: false
      send_data audio.data, type: audio.content_type, disposition: "inline"
    end
  end
end
