# frozen_string_literal: true

module Manipule
  # Ce que l'enseignante désigne : la compétence qu'un élève travaille
  # aujourd'hui. Une seule est active à la fois, les précédentes restent pour
  # l'historique.
  class Assignment < ApplicationRecord
    belongs_to :student
    belongs_to :skill
    belongs_to :user

    scope :active, -> { where(active: true) }

    # Désigner, c'est remplacer : une affectation active chasse l'autre, dans la
    # même transaction, pour qu'aucun élève ne se retrouve avec deux compétences
    # du jour ni aucune.
    def self.designer!(student:, skill:, user:)
      transaction do
        active.where(student:).update_all(active: false, updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
        create!(student:, skill:, user:)
      end
    end

    def self.courante(student)
      active.find_by(student:)
    end
  end
end
