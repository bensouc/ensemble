# frozen_string_literal: true

class Figure
  # Zone de manipulation : un cadre où le matériel (Figure::Materiel) se pose
  # librement, sur une grille aimantée d'un quart d'em. Comme toute figure, la
  # zone est entièrement décrite par son identifiant — sa taille, puis chaque
  # élément et sa place, en pas de grille :
  #
  #   zone-80x24-b10.4.8_p2.20.8   20 × 6 em : un billet de 10 €, une pièce de 2 €
  #
  # Pas de table, donc rien à dupliquer au clonage ; modifier une zone, c'est en
  # insérer une autre à sa place, comme on change l'heure d'une horloge
  # (editeur_enonce_controller, editeur/zone.js).
  module Zone
    PAS_DE_LA_GRILLE = 0.25 # em
    LARGEURS = (16..240) # pas : de 4 à 60 em
    HAUTEURS = (8..160) # pas : de 2 à 40 em
    ELEMENTS_AU_PLUS = 60
    CODES = { "b5" => "billet-5", "b10" => "billet-10", "b20" => "billet-20", "b50" => "billet-50",
              "b100" => "billet-100", "p1" => "piece-1", "p2" => "piece-2", "u" => "bloc-unite",
              "d" => "bloc-dizaine", "c" => "bloc-centaine", "m" => "bloc-millier" }.freeze
    IDENTIFIANT = /\Azone-(?<largeur>\d{1,3})x(?<hauteur>\d{1,3})(?:-(?<elements>[a-z0-9._]+))?\z/
    ELEMENT = /\A(?<code>[a-z]+\d*)\.(?<x>\d{1,3})\.(?<y>\d{1,3})\z/

    # La zone, en pas de grille : sa taille et la place de chaque élément.
    def zone_dessin
      { largeur: @zone[:largeur], hauteur: @zone[:hauteur],
        largeur_em: @zone[:largeur] * PAS_DE_LA_GRILLE, hauteur_em: @zone[:hauteur] * PAS_DE_LA_GRILLE,
        elements: @zone[:elements].map { |element| element_dessine(element) } }
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
      { materiel: Figure.find(CODES[match[:code]]), x:, y: } if x < largeur && y < hauteur
    end

    def element_dessine(element)
      largeur, hauteur = element[:materiel].taille_du_materiel.map { |em| arrondi(em / PAS_DE_LA_GRILLE) }
      { **element, largeur:, hauteur: }
    end
  end
end
