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

    # Le code de l'« Espace professeur.e » : sans lui, un élève qui trouve la
    # porte de l'adulte quitte le jeu. Facultatif — sans code, la porte reste
    # libre. Seule son empreinte est gardée.
    has_secure_password :code_prof, validations: false
    validates :code_prof, length: { minimum: 4 }, allow_nil: true

    def code_prof?
      code_prof_digest.present?
    end

    # Libre sans code ; sinon, le bon code.
    def porte_ouverte?(code)
      !code_prof? || authenticate_code_prof(code.to_s).present?
    end

    def self.pour!(classroom)
      find_or_create_by!(classroom:)
    end

    def renouveler!
      regenerate_token
    end
  end
end
