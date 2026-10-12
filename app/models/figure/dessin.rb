# frozen_string_literal: true

class Figure
  # La géométrie des figures dessinées en SVG : ligne Seyès et cadran d'horloge.
  module Dessin
    # Plan de travail et fiche de ceinture sont mis en page sur 1000 px, que
    # Chrome ramène à la largeur utile d'un A4 : tout sort à 75,8 % (mesuré le
    # 12/10/2026, barre étalon de 100 mm imprimée à 75,8 mm). La ligne Seyès est
    # grossie d'autant dans le PDF pour retomber sur ses 8 mm à la règle.
    ECHELLE_IMPRESSION = 1.32
    PX_PAR_MM = 96 / 25.4

    # Ligne Seyès, en pixels CSS : un carreau de 8 mm, trois lignes fines et une
    # forte (à 6 mm, comme sur le cahier : trois interlignes au-dessus pour les
    # hampes, un en dessous pour les jambages), une verticale. En SVG : les
    # dégradés CSS sortaient irréguliers à l'impression.
    def seyes_geometrie(pdf: false)
      mm = PX_PAR_MM * (pdf ? ECHELLE_IMPRESSION : 1)
      fin = 0.25 * mm
      {
        carreau: 8 * mm, fin:, fort: 0.4 * mm,
        fines: [fin / 2, 2 * mm, 4 * mm], forte: 6 * mm,
        marge: marge? ? 15 * mm : 0,
        motif: "rt-seyes-#{pdf ? 'pdf' : 'ecran'}#{'-marge' if marge?}"
      }.transform_values { |valeur| valeur.is_a?(String) ? valeur : arrondi(valeur) }
    end

    # Ligne simple pour écrire dessus : 10 mm de haut, le trait en bas.
    def ligne_geometrie(pdf: false)
      mm = PX_PAR_MM * (pdf ? ECHELLE_IMPRESSION : 1)
      hauteur = 10 * mm
      trait = 0.3 * mm
      { hauteur:, trait:, y: hauteur - (trait / 2) }.transform_values { |valeur| arrondi(valeur) }
    end

    # Le cadran se dessine dans un carré de 200 de côté, centre (100, 100).
    def graduations
      (0...60).map do |minute|
        grande = (minute % 5).zero?
        x1, y1 = point_sur_cadran(minute * 6, grande ? 78 : 84)
        x2, y2 = point_sur_cadran(minute * 6, 90)
        { x1:, y1:, x2:, y2:, epaisseur: grande ? 3.5 : 1.5 }
      end
    end

    def chiffres_du_cadran
      (1..12).map do |heure|
        x, y = point_sur_cadran(heure * 30, 64)
        { x:, y:, texte: heure.to_s }
      end
    end

    def petite_aiguille
      point_sur_cadran(((heures % 12) + (minutes / 60.0)) * 30, 44)
    end

    def grande_aiguille
      point_sur_cadran(minutes * 6, 72)
    end

    private

    def arrondi(valeur)
      valeur.is_a?(Array) ? valeur.map { |v| v.round(3) } : valeur.round(3)
    end

    # Angle en degrés, compté depuis midi dans le sens des aiguilles d'une montre.
    def point_sur_cadran(angle, rayon)
      radians = angle * Math::PI / 180
      [(100 + (rayon * Math.sin(radians))).round(2), (100 - (rayon * Math.cos(radians))).round(2)]
    end
  end
end
