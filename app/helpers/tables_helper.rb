# frozen_string_literal: true

module TablesHelper
  # Classes d'une cellule de tableau ActionText.
  #
  # Tout l'état de mise en forme passe par des classes plutôt que par des
  # attributs `data-*` : dans l'éditeur, le balisage traverse le sanitizer de
  # Trix, qui ne conserve que `style href src width height class language`.
  # `class` est donc le seul canal disponible — et il l'est aussi côté
  # affichage, où c'est le sanitizer de Rails qui s'applique.
  def table_cell_classes(table, row, col)
    classes = ["rt-cell"]

    align = table.align_for(col)
    classes << "rt-al-#{align}" unless align == "left"

    table.styles_for(row, col).each { |flag| classes << "rt-c-#{flag}" }

    classes.join(" ")
  end

  # La couleur du texte est le seul réglage qui ne passe pas par une classe : sa
  # valeur est libre. `style` fait partie des attributs conservés aussi bien par
  # le sanitizer de Trix que par celui de Rails, et le modèle n'y laisse entrer
  # que des teintes de sa liste blanche.
  def table_cell_style(table, row, col)
    color = table.color_for(row, col)
    "color: #{color}" if color
  end
end
