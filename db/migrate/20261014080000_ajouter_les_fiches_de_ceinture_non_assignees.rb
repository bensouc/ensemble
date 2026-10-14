# frozen_string_literal: true

# Une fiche de ceinture peut n'être celle d'aucun élève : le professeur la
# génère depuis les exercices de ceinture, pour un niveau, et l'imprime telle
# quelle. Elle porte alors son niveau, que la fiche d'un élève tient de sa
# classe.
#
# Aucune reprise : toutes les fiches existantes ont un élève.
class AjouterLesFichesDeCeintureNonAssignees < ActiveRecord::Migration[8.1]
  def change
    change_column_null :belt_sheets, :student_id, true
    add_reference :belt_sheets, :grade, foreign_key: { on_delete: :cascade }
  end
end
