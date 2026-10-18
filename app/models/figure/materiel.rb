# frozen_string_literal: true

class Figure
  # Matériel de manipulation : billets, pièces, blocs de numération. Dessiné
  # plutôt que photographié : un billet simplifié aux couleurs du vrai ne peut
  # pas être pris pour lui, ce qu'exige la BCE de toute reproduction de billet
  # en euros. Les dessins sont dans figures/_billet_svg, _piece_svg, _bloc_svg.
  #
  # Tailles en em : le matériel suit le texte qui l'entoure, plus grand au PDF
  # (20 px) qu'à l'écran (17 px), comme un pictogramme.
  module Materiel
    SORTES = {
      "billet" => %w[5 10 20 50 100],
      "piece" => %w[1 2],
      "bloc" => %w[unite dizaine centaine millier]
    }.freeze
    IDENTIFIANT = /\A(?<sorte>billet|piece|bloc)-(?<valeur>[a-z0-9]+)\z/
    NOMS_DES_BLOCS = { "unite" => "Une unité", "dizaine" => "Une dizaine",
                       "centaine" => "Une centaine", "millier" => "Un millier" }.freeze

    # Billets aux couleurs des vrais : 5 gris, 10 rouge, 20 bleu, 50 orange, 100 vert.
    COULEURS_DES_BILLETS = {
      "5" => { fond: "#E3E5E8", trait: "#6F747C" },
      "10" => { fond: "#F6CFCB", trait: "#C2433A" },
      "20" => { fond: "#CFE2F6", trait: "#3A73BC" },
      "50" => { fond: "#FBDDB8", trait: "#C96F22" },
      "100" => { fond: "#CDE9CB", trait: "#3B8C43" }
    }.freeze
    HAUTEUR_D_UN_BILLET = 1.7 # em

    # Pièces : 1 € à cœur argent et couronne dorée, 2 € l'inverse ; la pièce de
    # 2 € est un peu plus grande, comme la vraie.
    OR = { fond: "#E8BE48", trait: "#A87A12" }.freeze
    ARGENT = { fond: "#D5D8DC", trait: "#8E949B" }.freeze
    TAILLES_DES_PIECES = { "1" => 1.4, "2" => 1.55 }.freeze # em

    # Blocs en perspective cavalière, quadrillés comme ceux de la classe :
    # largeur × hauteur × profondeur, en unités ; la profondeur fuit de moitié.
    # Une unité vaut 10 dans le dessin et 0,35 em à l'affichage.
    DIMENSIONS_DES_BLOCS = { "unite" => [1, 1, 1], "dizaine" => [1, 10, 1],
                             "centaine" => [10, 10, 1], "millier" => [10, 10, 10] }.freeze
    # Devant, dessus (plus clair), côté (plus foncé).
    COULEURS_DES_BLOCS = {
      "unite" => %w[#F6C343 #FBDD86 #D9A520], "dizaine" => %w[#5DBB4F #94D487 #3E9334],
      "centaine" => %w[#3FA9E8 #85C9F2 #2381BF], "millier" => %w[#E2445C #EE8394 #B92E44]
    }.freeze
    PAS = 10
    UNITE_EN_EM = 0.35

    def materiel?
      SORTES.key?(kind.to_s)
    end

    def libelle_du_materiel
      case kind
      when :billet then "Billet de #{valeur} €"
      when :piece then "Pièce de #{valeur} €"
      when :bloc then NOMS_DES_BLOCS.fetch(valeur)
      end
    end

    def billet_dessin
      { **COULEURS_DES_BILLETS.fetch(valeur), hauteur: HAUTEUR_D_UN_BILLET,
                                              largeur: arrondi(HAUTEUR_D_UN_BILLET * 130 / 68.0) }
    end

    def piece_dessin
      couronne, coeur = valeur == "1" ? [OR, ARGENT] : [ARGENT, OR]
      { couronne:, coeur:, taille: TAILLES_DES_PIECES.fetch(valeur) }
    end

    def bloc_dessin
      largeur, hauteur, profondeur = DIMENSIONS_DES_BLOCS.fetch(valeur).map { |n| n * PAS }
      fuite = profondeur / 2.0
      { **bloc_faces(largeur, hauteur, fuite), **bloc_cadre(largeur, hauteur, fuite),
        couleurs: COULEURS_DES_BLOCS.fetch(valeur), grille: trace(bloc_grille(largeur, hauteur, fuite)) }
    end

    # Largeur et hauteur d'un matériel, en em : celles de son dessin, que
    # l'image de l'éditeur reprend.
    def taille_du_materiel
      case kind
      when :billet then billet_dessin.values_at(:largeur, :hauteur)
      when :piece then [piece_dessin[:taille]] * 2
      when :bloc then bloc_dessin.values_at(:largeur_em, :hauteur_em)
      end
    end

    private

    def parse_materiel
      match = id.match(IDENTIFIANT)
      return unless match && SORTES.fetch(match[:sorte]).include?(match[:valeur])

      @valeur = match[:valeur]
      match[:sorte].to_sym
    end

    def bloc_faces(largeur, hauteur, fuite)
      { devant: [[0, fuite], [largeur, fuite], [largeur, fuite + hauteur], [0, fuite + hauteur]],
        dessus: [[0, fuite], [fuite, 0], [largeur + fuite, 0], [largeur, fuite]],
        cote: [[largeur, fuite], [largeur + fuite, 0], [largeur + fuite, hauteur], [largeur, fuite + hauteur]] }.
        transform_values { |coins| coins.map { |coin| point(coin) }.join(" ") }
    end

    # Le quadrillage : un trait par unité sur chaque face visible.
    def bloc_grille(largeur, hauteur, fuite)
      grille_en_largeur(largeur, hauteur, fuite) + grille_en_hauteur(largeur, hauteur, fuite) +
        grille_en_profondeur(largeur, hauteur, fuite)
    end

    # Devant et dessus, un trait par colonne.
    def grille_en_largeur(largeur, hauteur, fuite)
      PAS.step(largeur - 1, PAS).flat_map { |x| [[[x, fuite], [x, fuite + hauteur]], [[x, fuite], [x + fuite, 0]]] }
    end

    # Devant et côté, un trait par rangée.
    def grille_en_hauteur(largeur, hauteur, fuite)
      PAS.step(hauteur - 1, PAS).flat_map do |y|
        [[[0, fuite + y], [largeur, fuite + y]], [[largeur, fuite + y], [largeur + fuite, y]]]
      end
    end

    # Dessus et côté, un trait par tranche de profondeur.
    def grille_en_profondeur(largeur, hauteur, fuite)
      (PAS / 2.0).step(fuite - 1, PAS / 2.0).flat_map do |d|
        [[[d, fuite - d], [largeur + d, fuite - d]], [[largeur + d, fuite - d], [largeur + d, fuite - d + hauteur]]]
      end
    end

    # La boîte du dessin, marge d'un trait comprise, et sa taille à l'affichage.
    def bloc_cadre(largeur, hauteur, fuite)
      boite = [largeur + fuite + 2, hauteur + fuite + 2].map { |n| arrondi(n) }
      { boite:, largeur_em: arrondi(boite[0] / PAS * UNITE_EN_EM), hauteur_em: arrondi(boite[1] / PAS * UNITE_EN_EM) }
    end

    def trace(segments)
      segments.map { |debut, fin| "M#{point(debut)}L#{point(fin)}" }.join
    end

    # Un point du dessin, décalé de la marge d'un trait.
    def point((x, y))
      "#{arrondi(x + 1)},#{arrondi(y + 1)}"
    end
  end
end
