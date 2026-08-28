# frozen_string_literal: true

# Les modèles rangés par l'enseignant : `Challenge`, `Skill`, `Domain`,
# `WorkPlanSkill`. Tous portent une colonne `position` tenue par `acts_as_list`.
#
# Ce concern existe pour une raison précise. `.sort` sur un tableau de ces
# enregistrements ne triait PAS par position : ActiveRecord définit `<=>` sur la
# clé primaire, et aucun de ces modèles ne le redéfinissait. Les listes
# sortaient donc dans l'ordre de leur création — silencieusement, à trois
# endroits, dont la page de résultats d'une classe et l'index des compétences.
# Rien ne signalait l'erreur : un ordre reste un ordre, il était simplement
# faux.
#
# Le corriger appel par appel aurait laissé le prochain `.sort` retomber dans le
# piège. Le corriger sur le modèle le rend impossible.
module Positionable
  extend ActiveSupport::Concern

  included do
    # L'ordre voulu, en SQL. `:id` départage les scopes où deux enregistrements
    # partagent une position — il y en a quatre dans la base.
    scope :ordered, -> { order(:position, :id) }
  end

  # Le même ordre, en Ruby : `sort`, `min` et `max` sur un tableau chargé.
  def <=>(other)
    return super unless other.instance_of?(self.class)

    [position.to_i, id.to_i] <=> [other.position.to_i, other.id.to_i]
  end
end
