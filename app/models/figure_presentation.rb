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
#
# Une zone de manipulation, elle, garde ses proportions : on l'agrandit en % de
# sa taille naturelle, « echelle-150 droite » (voir `attributs_de_zone`).
module FigurePresentation
  TAILLE_MIN = 10
  TAILLE_MAX = 100
  POSITIONS = %w[gauche centre droite].freeze
  FORMAT = /\Ataille-(?<taille>\d+)(?: (?<position>[a-z]+))?\z/
  ECHELLES = (50..400)
  FORMAT_DE_ZONE = /\A(?:echelle-(?<echelle>\d+) ?)?(?<position>[a-z]*)\z/

  module_function

  # Classes et style du <figure> rendu. `attachment` : l'ActionText::Attachment
  # (les partials le reçoivent sous le nom de leur attachable).
  def attributs(attachment, defaut: nil)
    taille, position = parse(attachment.try(:node)&.[]("presentation")) || parse(defaut)
    return { classes: [], style: nil } unless taille

    { classes: ["rt-fig", ("rt-fig--#{position}" if position)].compact, style: "width: #{taille}%" }
  end

  # Classes du <figure> d'une zone et son échelle, en % : le dessin, mesuré en
  # em, est agrandi d'autant (figures/_zone_svg). Il garde ainsi la même taille
  # par rapport au texte à l'écran, à l'affichage et au PDF — une part de la
  # ligne, elle, change avec la largeur de la page.
  def attributs_de_zone(attachment)
    match = attachment.try(:node)&.[]("presentation").to_s.match(FORMAT_DE_ZONE)
    position = match[:position] if match && POSITIONS.include?(match[:position])
    echelle = match&.[](:echelle).to_i
    {
      classes: position ? ["rt-fig", "rt-fig--#{position}"] : [],
      echelle: ECHELLES.cover?(echelle) ? echelle : 100
    }
  end

  def parse(presentation)
    match = presentation.to_s.match(FORMAT)
    return unless match

    taille = match[:taille].to_i
    return unless taille.between?(TAILLE_MIN, TAILLE_MAX)

    [taille, (match[:position] if POSITIONS.include?(match[:position]))]
  end
end
