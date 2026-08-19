# frozen_string_literal: true

# Couleur du texte, par cellule.
#
# Format : { "<ligne>-<colonne>" => "#rrggbb" }, creux comme `data`.
# Défautée, donc les tableaux existants sont inchangés.
class AddCellColorsToTables < ActiveRecord::Migration[7.1]
  def change
    add_column :tables, :cell_colors, :json, default: {}
  end
end
