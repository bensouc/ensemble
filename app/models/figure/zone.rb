# frozen_string_literal: true

class Figure
  # Zone de manipulation : un cadre où le matériel (Figure::Materiel) se pose
  # librement, sur une grille aimantée d'un quart d'em. Comme toute figure, la
  # zone est entièrement décrite par son identifiant — sa taille, puis chaque
  # élément et sa place, en pas de grille :
  #
  #   zone-80x24-b10.4.8_p2.20.8.150   20 × 6 em : un billet de 10 €, une pièce
  #                                    de 2 € agrandie à 150 %
  #
  # Pas de table, donc rien à dupliquer au clonage ; modifier une zone, c'est en
  # insérer une autre à sa place, comme on change l'heure d'une horloge
  # (editeur_enonce_controller, editeur/zone.js).
  module Zone
    PAS_DE_LA_GRILLE = 0.25 # em
    LARGEURS = (16..240) # pas : de 4 à 60 em
    HAUTEURS = (8..160) # pas : de 2 à 40 em
    ELEMENTS_AU_PLUS = 60
    TAILLES = (50..400) # % de la taille du matériel
    CODES = { "b5" => "billet-5", "b10" => "billet-10", "b20" => "billet-20", "b50" => "billet-50",
              "b100" => "billet-100", "pc1" => "piece-1c", "pc2" => "piece-2c", "pc5" => "piece-5c",
              "pc10" => "piece-10c", "pc20" => "piece-20c", "pc50" => "piece-50c",
              "p1" => "piece-1", "p2" => "piece-2", "u" => "bloc-unite",
              "d" => "bloc-dizaine", "c" => "bloc-centaine", "m" => "bloc-millier" }.freeze
    IDENTIFIANT = /\Azone-(?<largeur>\d{1,3})x(?<hauteur>\d{1,3})(?:-(?<elements>[a-z0-9._]+))?\z/
    ELEMENT = /\A(?<code>[a-z]+\d*)\.(?<x>\d{1,3})\.(?<y>\d{1,3})(?:\.(?<taille>\d{2,3}))?\z/
    # La zone neuve que propose l'éditeur, en pas : 20 × 6 em.
    NEUVE = [80, 24].freeze

    # Une seule figure par matériel, partagée par toutes les zones : son dessin
    # n'est calculé qu'une fois.
    def self.materiel(code)
      (@materiel ||= {})[code] ||= Figure.find(CODES.fetch(code))
    end

    # La zone, en pas de grille : sa taille et la place de chaque élément.
    def zone_dessin
      @zone_dessin ||= { largeur: @zone[:largeur], hauteur: @zone[:hauteur],
                         largeur_em: largeur_naturelle_em, hauteur_em: @zone[:hauteur] * PAS_DE_LA_GRILLE,
                         elements: @zone[:elements].map { |element| element_dessine(element) } }
    end

    # La zone telle qu'on l'imprime : rognée au plus près du matériel. Le PDF ne
    # dessine pas le cadre, et son vide s'y lisait comme une marge autour du
    # matériel, plus grande en bas qu'en haut. Une zone vide garde son cadre.
    def zone_imprimee
      dessin = zone_dessin
      elements = dessin[:elements]
      return dessin if elements.empty?

      gauche, largeur = etendue(elements, :x, :largeur, dessin[:largeur])
      haut, hauteur = etendue(elements, :y, :hauteur, dessin[:hauteur])
      { largeur:, hauteur:, largeur_em: largeur * PAS_DE_LA_GRILLE, hauteur_em: hauteur * PAS_DE_LA_GRILLE,
        elements: elements.map { |element| element.merge(x: element[:x] - gauche, y: element[:y] - haut) } }
    end

    # La largeur que la figure prend d'elle-même, en em ; nil pour une figure
    # qui suit la largeur de la ligne.
    def largeur_naturelle_em
      @zone[:largeur] * PAS_DE_LA_GRILLE if @zone
    end

    private

    def parse_zone
      match = id.match(IDENTIFIANT) or return
      largeur = match[:largeur].to_i
      hauteur = match[:hauteur].to_i
      return unless LARGEURS.cover?(largeur) && HAUTEURS.cover?(hauteur)

      elements = elements_de_zone(match[:elements].to_s, largeur, hauteur) or return
      @zone = { largeur:, hauteur:, elements: }
      :zone
    end

    # Les éléments de la zone, ou nil si l'un d'eux ne vaut rien.
    def elements_de_zone(texte, largeur, hauteur)
      elements = texte.split("_").map { |element| element_de_zone(element, largeur, hauteur) }
      elements if elements.size <= ELEMENTS_AU_PLUS && elements.none?(&:nil?)
    end

    # Un élément posé dans la zone (son coin haut gauche y est), ou nil.
    def element_de_zone(texte, largeur, hauteur)
      match = texte.match(ELEMENT)
      return unless match && CODES.key?(match[:code])

      x = match[:x].to_i
      y = match[:y].to_i
      taille = (match[:taille] || 100).to_i
      return unless x < largeur && y < hauteur && TAILLES.cover?(taille)

      { materiel: Zone.materiel(match[:code]), x:, y:, taille: }
    end

    # L'étendue du matériel sur un axe, en pas : où il commence, et sur quelle
    # longueur. Elle s'arrête au cadre, qui coupe à l'écran ce qui en déborde.
    def etendue(elements, debut, longueur, cadre)
      premier = elements.pluck(debut).min
      dernier = [elements.map { |element| element[debut] + element[longueur] }.max, cadre].min
      [premier, (dernier - premier).round(2)]
    end

    def element_dessine(element)
      largeur, hauteur = element[:materiel].taille_en_pas(element[:taille])
      { **element, largeur:, hauteur: }
    end
  end
end
