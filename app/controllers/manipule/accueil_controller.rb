# frozen_string_literal: true

module Manipule
  # La porte d'entrée de l'enseignante.
  #
  # Manipule a cinq écrans qui ne se devinent pas les uns depuis les autres :
  # sans cette page et la barre qu'elle partage, il fallait taper les adresses
  # à la main. Elle ne fait rien d'autre que compter et orienter.
  class AccueilController < ProfController
    def index
      problemes = policy_scope(Problem)
      @en_circulation = problemes.published.count
      @brouillons = problemes.count - @en_circulation
      @competences = problemes.distinct.count(:skill_id)

      classes = policy_scope(Classroom)
      @classes = classes.count
      @classes_equipees = Assignment.active.joins(student: :classroom).
        where(classrooms: { id: classes.select(:id) }).
        distinct.count("classrooms.id")
    end
  end
end
