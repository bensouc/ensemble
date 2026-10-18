# frozen_string_literal: true

class Figure
  # Matériel de manipulation : billets, pièces, blocs de numération, que l'on
  # pose dans une zone (Figure::Zone). Dessiné plutôt que photographié : un
  # billet simplifié aux couleurs du vrai ne peut pas être pris pour lui, ce
  # qu'exige la BCE de toute reproduction de billet en euros. Les formes sont
  # dans figures/_billet_formes, _piece_formes, _bloc_formes.
  #
  # Tailles en em : le matériel suit le texte, plus grand au PDF (20 px) qu'à
  # l'écran (17 px).
  module Materiel
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

    # Pièces : 1 € à cœur argent et couronne dorée, 2 € l'inverse ; les centimes
    # d'une seule couleur, cuivre (1, 2, 5) ou or (10, 20, 50). Les diamètres
    # suivent ceux des vraies pièces (16,25 mm pour 1 c, 25,75 mm pour 2 €), à
    # l'échelle de la pièce de 1 € : 1,4 em pour 23,25 mm.
    OR = { fond: "#E8BE48", trait: "#A87A12" }.freeze
    ARGENT = { fond: "#D5D8DC", trait: "#8E949B" }.freeze
    CUIVRE = { fond: "#D98B5F", trait: "#9A5130" }.freeze
    TAILLES_DES_PIECES = { "1c" => 0.98, "2c" => 1.13, "5c" => 1.28, "10c" => 1.19, "20c" => 1.34,
                           "50c" => 1.46, "1" => 1.4, "2" => 1.55 }.freeze # em

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

    SORTES = { "billet" => COULEURS_DES_BILLETS.keys, "piece" => TAILLES_DES_PIECES.keys,
               "bloc" => DIMENSIONS_DES_BLOCS.keys }.freeze
    BOITE_D_UN_BILLET = [130, 68].freeze
    BOITE_D_UNE_PIECE = 44

    def libelle_du_materiel
      case kind
      when :billet then "Billet de #{valeur} €"
      when :piece then centimes? ? "Pièce de #{valeur.to_i} centime#{'s' if valeur.to_i > 1}" : "Pièce de #{valeur} €"
      when :bloc then NOMS_DES_BLOCS.fetch(valeur)
      end
    end

    # Le cadre du dessin (`viewBox`) et sa taille en em.
    def cadre_du_materiel
      boite, largeur, hauteur = case kind
                                when :billet then [BOITE_D_UN_BILLET, billet_dessin[:largeur], HAUTEUR_D_UN_BILLET]
                                when :piece then [[BOITE_D_UNE_PIECE] * 2, *[piece_dessin[:taille]] * 2]
                                when :bloc then [bloc_dessin[:boite], *bloc_dessin.values_at(:largeur_em, :hauteur_em)]
                                end
      { boite: "0 0 #{boite.join(' ')}", largeur:, hauteur: }
    end

    # La taille du matériel en pas de la grille d'une zone, à `taille` %.
    def taille_en_pas(taille = 100)
      cadre_du_materiel.values_at(:largeur, :hauteur).map { |em| arrondi(em / Zone::PAS_DE_LA_GRILLE * taille / 100.0) }
    end

    def billet_dessin
      largeur, hauteur = BOITE_D_UN_BILLET
      { **COULEURS_DES_BILLETS.fetch(valeur), largeur: arrondi(HAUTEUR_D_UN_BILLET * largeur / hauteur.to_f) }
    end

    # Une pièce en euros a un cœur d'une autre couleur ; une pièce en centimes
    # n'a qu'un métal (`couronne`), et un filet en guise de cœur.
    def piece_dessin
      couronne, coeur = if centimes? then [%w[1c 2c 5c].include?(valeur) ? CUIVRE : OR, nil]
                        elsif valeur == "1" then [OR, ARGENT]
                        else [ARGENT, OR]
                        end
      { couronne:, coeur:, taille: TAILLES_DES_PIECES.fetch(valeur), nombre: valeur.to_i, unite: centimes? ? "c" : "€" }
    end

    def centimes?
      kind == :piece && valeur.end_with?("c")
    end

    # Faces et quadrillage : calculés une fois par figure (une zone réutilise la
    # même pour tous ses blocs pareils, Zone.materiel).
    def bloc_dessin
      @bloc_dessin ||= begin
        largeur, hauteur, profondeur = DIMENSIONS_DES_BLOCS.fetch(valeur).map { |n| n * PAS }
        fuite = profondeur / 2.0
        { **bloc_faces(largeur, hauteur, fuite), **bloc_cadre(largeur, hauteur, fuite),
          couleurs: COULEURS_DES_BLOCS.fetch(valeur), grille: trace(bloc_grille(largeur, hauteur, fuite)) }
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
