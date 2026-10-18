# frozen_string_literal: true

# Une fiche de ceinture se renomme, comme un plan de travail. Sans nom donné,
# elle garde celui de toujours : le prénom de l'élève, ou ses blocs pour une
# fiche non assignée (`BeltSheet#nom`).
#
# Aucune reprise : un nom vide vaut le nom par défaut.
class AjouterLeNomDesFichesDeCeinture < ActiveRecord::Migration[8.1]
  def change
    add_column :belt_sheets, :name, :string
  end
end
