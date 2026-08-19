# frozen_string_literal: true

# Mise en forme des tableaux ActionText.
#
# Les trois colonnes sont défautées, donc les tableaux existants gardent
# exactement le rendu actuel : pas de ligne d'en-tête, alignement à gauche,
# aucun style de cellule.
#
# Formats :
#   header_row  : booléen, la première ligne devient des <th>
#   col_aligns  : ["left", "center", "right", …], un élément par colonne
#   cell_styles : { "<ligne>-<colonne>" => ["b", "i", "u"] }, creux comme `data`
class AddLayoutOptionsToTables < ActiveRecord::Migration[7.1]
  def change
    add_column :tables, :header_row, :boolean, default: false, null: false
    add_column :tables, :col_aligns, :json, default: []
    add_column :tables, :cell_styles, :json, default: {}
  end
end
