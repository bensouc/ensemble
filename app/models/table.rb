# frozen_string_literal: true

# Tableau « maison » d'un énoncé, pièce jointe ActionText de l'ancien éditeur
# (Trix). L'éditeur TipTap ne l'édite plus : il le convertit en tableau natif à
# l'ouverture de l'énoncé (EditeurTiptap). Il ne sert donc plus qu'à afficher
# les énoncés pas encore rouverts, et à les cloner.
#
# Format de `data` (inchangé, historique) : { "<ligne>-<colonne>" => "texte" }.
# La grille est creuse : une cellule jamais éditée est absente du hash.
#
# Les colonnes de mise en forme (header_row, col_aligns, cell_styles) sont
# toutes optionnelles : un tableau créé avant leur introduction se rend à
# l'identique.
class Table < ApplicationRecord
  include GlobalID::Identification
  include ActionText::Attachable

  ALIGNMENTS = %w[left center right].freeze
  CELL_STYLE_FLAGS = %w[b i u].freeze

  # La couleur d'une cellule est écrite en `style` inline à l'affichage
  # (TablesHelper#table_cell_style). Liste blanche plutôt que validation de
  # format : aucune valeur arbitraire venue de la base ne peut atteindre l'attribut.
  TEXT_COLORS = %w[#3D3D3D #9C9C9C #F24150 #C44003 #E67E22 #4CAF50 #167FFB #7C5CE7].freeze

  # --- Lecture ---------------------------------------------------------------

  def cell(row, col)
    data[key(row, col)]
  end

  def align_for(col)
    align = Array(col_aligns)[col]
    ALIGNMENTS.include?(align) ? align : "left"
  end

  def color_for(row, col)
    color = cell_colors.is_a?(Hash) ? cell_colors[key(row, col)] : nil
    color if TEXT_COLORS.include?(color)
  end

  def styles_for(row, col)
    Array(cell_styles.is_a?(Hash) ? cell_styles[key(row, col)] : nil) & CELL_STYLE_FLAGS
  end

  def header_row?
    header_row == true
  end

  # Copie persistée du tableau, mise en forme comprise.
  #
  # Nommée explicitement : la version précédente s'appelait `clone` et écrasait
  # donc `Object#clone`, dont la sémantique Ruby est tout autre (copie
  # superficielle, non persistée).
  def duplicate
    dup.tap(&:save!)
  end

  private

  def key(row, col)
    "#{row}-#{col}"
  end
end
