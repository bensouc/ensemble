# frozen_string_literal: true

module Manipule
  # Une réponse proposée. Les trois d'un problème sont mélangées à l'affichage :
  # leur ordre en base ne dit rien à l'élève.
  class Choice < ApplicationRecord
    belongs_to :problem, inverse_of: :choices

    # Même raison que sur le problème : le lien est polymorphe, donc la base
    # ne nettoie rien toute seule.
    has_many :audios, as: :readable, class_name: "Manipule::Audio", dependent: :destroy

    validates :label, presence: true

    # Seulement sur modification : la création d'une réponse accompagne celle
    # de son problème, dont le propre déclencheur suffit.
    after_commit :programmer_audio, on: :update

    private

    def programmer_audio
      return unless saved_change_to_label?
      return unless problem&.published?

      GenererAudioJob.perform_later(problem)
    end
  end
end
