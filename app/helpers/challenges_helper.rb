# frozen_string_literal: true

module ChallengesHelper
  # Le fond d'un sélecteur de ceinture prend la couleur de la ceinture : on
  # reconnaît le niveau à la teinte avant d'avoir lu le mot.
  #
  # Ces classes vivaient en dur dans le filtre de l'index, écrites DEUX fois —
  # une pour les options, une pour le champ. Les recopier une troisième fois
  # dans la modale de déplacement les aurait fait diverger tôt ou tard.
  #
  # Les ceintures foncées passent le texte en blanc, sinon il disparaît dessus.
  CLASSES_CEINTURE = [
    "--bgc-blanc",
    "--bgc-jaune",
    "--bgc-orange",
    "--bgc-vert --blanc",
    "--bgc-bleuC --blanc",
    "--bgc-marron --blanc",
    "--bgc-noir --blanc"
  ].freeze

  # Les bornes sont vérifiées : `CLASSES_CEINTURE[0 - 1]` renvoie le DERNIER
  # élément — l'indexation négative de Ruby — donc un niveau 0 ou vide peignait
  # le champ en ceinture noire. L'expression en dur du filtre de l'index avait
  # la même faille.
  def classe_ceinture(niveau)
    rang = niveau.to_i
    return "" unless rang.between?(1, CLASSES_CEINTURE.size)

    CLASSES_CEINTURE[rang - 1]
  end

  # Les sept ceintures pour un `select`, chacune sur son fond.
  #
  # Les libellés viennent de `Belt::BELT_COLORS`, donc accordés au féminin —
  # « ceinture verte », et non « Vert » comme l'écrivait le filtre de l'index.
  def options_ceintures(selectionnee)
    options_for_select(
      Belt::BELT_COLORS.each_with_index.map { |nom, i| [nom.capitalize, i + 1, { class: classe_ceinture(i + 1) }] },
      selectionnee
    )
  end
end
