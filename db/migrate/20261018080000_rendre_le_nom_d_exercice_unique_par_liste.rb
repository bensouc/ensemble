# frozen_string_literal: true

# Le nom d'un exercice était unique par compétence, toutes listes confondues :
# un exercice de ceinture ne pouvait pas porter le nom d'un exercice de plan de
# travail de la même compétence. Il l'est désormais par compétence ET par liste
# (`for_belt`), comme l'ordre des exercices.
#
# Aucune reprise : les noms en base respectent déjà la règle plus stricte.
class RendreLeNomDExerciceUniqueParListe < ActiveRecord::Migration[8.1]
  def change
    remove_index :challenges, %i[skill_id name], unique: true, name: "index_challenges_on_skill_id_and_name"
    add_index :challenges, %i[skill_id for_belt name], unique: true
  end
end
