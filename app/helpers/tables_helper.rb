# frozen_string_literal: true

module TablesHelper
  # Classes d'une cellule de tableau ActionText.
  #
  # Tout l'état de mise en forme passe par des classes plutôt que par des
  # attributs `data-*` : dans l'éditeur, le balisage traverse le sanitizer de
  # Trix, qui ne conserve que `style href src width height class language`.
  # `class` est donc le seul canal disponible — et il l'est aussi côté
  # affichage, où c'est le sanitizer de Rails qui s'applique.
  def table_cell_classes(table, row, col, editing: false)
    classes = ["rt-cell", editing ? "table-cell" : "table-cell-display"]

    align = table.align_for(col)
    classes << "rt-al-#{align}" unless align == "left"

    table.styles_for(row, col).each { |flag| classes << "rt-c-#{flag}" }

    classes.join(" ")
  end
end
