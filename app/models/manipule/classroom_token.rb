# frozen_string_literal: true

module Manipule
  # L'adresse par laquelle les élèves d'une classe entrent, sans compte ni mot
  # de passe. Le jeton est long et aléatoire ; l'enseignante peut le renouveler,
  # ce qui ferme aussitôt l'ancienne adresse.
  #
  # Ce que ça n'empêche pas, et qui est assumé : qui possède l'adresse peut se
  # faire passer pour n'importe quel élève de la classe. Ce qui est exposé, ce
  # sont des prénoms et des résultats d'entraînement.
  class ClassroomToken < ApplicationRecord
    has_secure_token :token, length: 24

    belongs_to :classroom

    validates :classroom_id, uniqueness: true

    def self.pour!(classroom)
      find_or_create_by!(classroom:)
    end

    def renouveler!
      regenerate_token
    end
  end
end
