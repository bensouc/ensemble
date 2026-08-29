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

  # Les sept ceintures, chacune sur son fond. Les libellés viennent de
  # `Belt::BELT_COLORS`, donc accordés au féminin — une ceinture est verte, pas
  # « Vert » comme l'écrivait le filtre de l'index.
  #
  # Cette forme — `[libellé, valeur, attributs]` — convient à `simple_form`
  # comme à `options_for_select`, qui en portent tous deux la classe.
  def collection_ceintures
    Belt::BELT_COLORS.each_with_index.map do |nom, index|
      [nom.capitalize, index + 1, { class: classe_ceinture(index + 1) }]
    end
  end

  def options_ceintures(selectionnee)
    options_for_select(collection_ceintures, selectionnee)
  end
end
