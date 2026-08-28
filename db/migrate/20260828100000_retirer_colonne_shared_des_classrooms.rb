# frozen_string_literal: true

# La colonne mentait. `Classroom#shared?` est redéfinie sur l'association, donc
# personne ne lisait `classrooms.shared` : elle était seulement écrite, à `true`
# au premier partage, et jamais remise à `false` au départ du dernier collègue
# (la condition `if classroom.shared_classrooms.count` était toujours vraie —
# `0` est truthy en Ruby — et aucun `save` ne suivait).
class RetirerColonneSharedDesClassrooms < ActiveRecord::Migration[7.1]
  def change
    remove_column :classrooms, :shared, :boolean
  end
end
