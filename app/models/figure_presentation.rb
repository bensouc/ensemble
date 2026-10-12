# frozen_string_literal: true

# Taille et position d'une image ou d'une figure dans l'énoncé.
#
# Elles sont portées par l'attribut `presentation` de la pièce jointe : c'est le
# seul attribut libre qu'ActionText conserve à l'enregistrement
# (`ActionText::TrixAttachment::COMPOSED_ATTRIBUTES`), et l'éditeur le relit tel
# quel à la réouverture. Valeur : « taille-50 centre ».
#
# La taille est libre, de 10 à 100 % de la largeur de l'énoncé : on la règle à la
# souris dans l'éditeur. Elle sort en `style="width: 33%"` — `width` en
# pourcentage passe le sanitizer d'ActionText, mesuré.
#
# Une image reçoit « gallery » à son insertion (c'est la présentation que Trix
# lui donnait). Une image déjà en place garde donc sa pleine largeur : rien ne
# change tant qu'on ne lui donne pas de taille.
module FigurePresentation
  TAILLE_MIN = 10
  TAILLE_MAX = 100
  POSITIONS = %w[gauche centre droite].freeze
  FORMAT = /\Ataille-(?<taille>\d+)(?: (?<position>[a-z]+))?\z/

  module_function

  # Classes et style du <figure> rendu. `attachment` : l'ActionText::Attachment
  # (les partials le reçoivent sous le nom de leur attachable).
  def attributs(attachment, defaut: nil)
    taille, position = parse(attachment.try(:node)&.[]("presentation")) || parse(defaut)
    return { classes: [], style: nil } unless taille

    { classes: ["rt-fig", ("rt-fig--#{position}" if position)].compact, style: "width: #{taille}%" }
  end

  def parse(presentation)
    match = presentation.to_s.match(FORMAT)
    return unless match

    taille = match[:taille].to_i
    return unless taille.between?(TAILLE_MIN, TAILLE_MAX)

    [taille, (match[:position] if POSITIONS.include?(match[:position]))]
  end
end
