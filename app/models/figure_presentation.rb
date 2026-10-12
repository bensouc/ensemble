# frozen_string_literal: true

# Taille et position d'une image ou d'une figure dans l'énoncé.
#
# Elles sont portées par l'attribut `presentation` de la pièce jointe Trix :
# c'est le seul attribut libre qu'ActionText conserve à l'enregistrement
# (`ActionText::TrixAttachment::COMPOSED_ATTRIBUTES`), et Trix le relit tel quel
# à la réouverture. Valeur : « taille-50 centre ».
#
# Trix y écrit lui-même « gallery » pour toute image ; c'est ce qui regroupe deux
# images consécutives en galerie. Une image déjà en place garde donc
# « gallery », et sa pleine largeur : rien ne change tant qu'on ne lui donne pas
# de taille.
module FigurePresentation
  TAILLES = %w[25 50 75 100].freeze
  POSITIONS = %w[gauche centre droite].freeze
  FORMAT = /\Ataille-(?<taille>\d+)(?: (?<position>[a-z]+))?\z/

  module_function

  # `attachment` : l'ActionText::Attachment rendu (les partials le reçoivent
  # sous le nom de leur attachable).
  def css_classes(attachment, defaut: nil)
    presentation = attachment.try(:node)&.[]("presentation")
    taille, position = parse(presentation) || parse(defaut)
    return [] unless taille

    ["rt-fig", "rt-fig--taille-#{taille}", ("rt-fig--#{position}" if position)].compact
  end

  def parse(presentation)
    match = presentation.to_s.match(FORMAT)
    return unless match && TAILLES.include?(match[:taille])

    [match[:taille], (match[:position] if POSITIONS.include?(match[:position]))]
  end
end
