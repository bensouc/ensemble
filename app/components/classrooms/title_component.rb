# frozen_string_literal: true

module Classrooms
  # Le titre d'une classe : son nom, et le niveau en plus petit à droite ; le
  # niveau seul quand elle n'a pas de nom. Les vues collaient jusqu'ici le
  # niveau et le nom — « CE2 - CE2 A », et « CE1 - » pour une classe sans nom.
  #
  # Pour un texte (mail, message, nom de fichier) : `Classroom#display_name`.
  class TitleComponent < ViewComponent::Base
    def initialize(classroom:)
      super()
      @classroom = classroom
    end

    def call
      return niveau if @classroom.name.blank?

      safe_join([@classroom.name, tag.small(niveau, class: "classroom-title-grade")], " ")
    end

    private

    def niveau
      @classroom.grade&.grade_level.to_s.upcase
    end
  end
end
