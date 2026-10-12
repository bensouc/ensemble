# frozen_string_literal: true

# Figure insérée dans l'énoncé d'un exercice : ligne Seyès, horloge, pictogramme.
#
# Pas de table en base. Une figure est entièrement décrite par son identifiant
# (`seyes-marge`, `ligne`, `horloge-0315-chiffres`, `picto-coche`), que le sgid signe et
# qu'ActionText retrouve par `Figure.find`. Conséquences, toutes voulues :
#
#   - rien à dupliquer au clonage d'un exercice, contrairement aux tableaux :
#     deux énoncés peuvent porter la même figure sans se marcher dessus ;
#   - rien à modifier : changer l'heure d'une horloge, c'est insérer une autre
#     figure à sa place. Pas de route de mise à jour, donc pas de droit à vérifier ;
#   - aucune ligne orpheline quand un énoncé est supprimé.
#
# La taille et la position d'une figure ne font PAS partie de l'identifiant :
# elles vivent dans l'attribut `presentation` de la pièce jointe, le même canal
# que pour une image (voir `FigurePresentation`).
class Figure
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include GlobalID::Identification
  include ActionText::Attachable
  include Figure::Dessin

  CONTENT_TYPE = "application/vnd.ensemble.figure"
  # Un pictogramme se place dans la phrase : il n'a ni taille ni position.
  INLINE_CONTENT_TYPE = "application/vnd.ensemble.figure-inline"

  PICTOS = {
    "coche" => "Coche",
    "croix" => "Croix",
    "case" => "Case à cocher",
    "crayon" => "Écris",
    "ciseaux" => "Découpe",
    "loupe" => "Observe",
    "bulle" => "Dis-le à voix haute"
  }.freeze

  # Tracés sur une grille de 24, aux couleurs des pastilles d'évaluation.
  # Dessinés plutôt qu'en émoji : le Chrome qui imprime les PDF n'a pas
  # forcément de police d'émoji en couleur, et chaque système les dessine à sa
  # façon.
  CERCLE = "M12 2a10 10 0 1 0 0.01 0z"
  DESSINS = {
    "coche" => [{ d: CERCLE, fill: "#4CAF50" }, { d: "M7 12.5l3.5 3.5L17 9", stroke: "#fff", width: 2.6 }],
    "croix" => [{ d: CERCLE, fill: "#CE3E1B" }, { d: "M8.5 8.5l7 7M15.5 8.5l-7 7", stroke: "#fff", width: 2.6 }],
    "case" => [{ d: "M4.5 4.5h15v15h-15z", fill: "#fff", stroke: "#3D3D3D", width: 2 }],
    "crayon" => [{ d: "M4 20l1-5L16 4l4 4L9 19z", fill: "#FFE3CF", stroke: "#C44003", width: 1.6 },
                 { d: "M14 6l4 4", stroke: "#C44003", width: 1.6 }],
    "ciseaux" => [{ d: "M6.5 4.5a2.5 2.5 0 1 0 .01 0zM6.5 14.5a2.5 2.5 0 1 0 .01 0z", stroke: "#3D3D3D", width: 1.6 },
                  { d: "M8.6 8.4L20 17M8.6 15.6L20 7", stroke: "#3D3D3D", width: 1.6 }],
    "loupe" => [{ d: "M10.5 4a6.5 6.5 0 1 0 .01 0z", fill: "#C8E6FB", stroke: "#167FFB", width: 1.8 },
                { d: "M15.5 15.5L20 20", stroke: "#167FFB", width: 2.4 }],
    "bulle" => [{ d: "M4 5h16v10H10l-4 4v-4H4z", fill: "#E7E4FA", stroke: "#7C5CE7", width: 1.6 }]
  }.freeze

  SEYES = /\Aseyes(?<marge>-marge)?\z/
  LIGNE = "ligne"
  PICTO = /\Apicto-(?<nom>[a-z]+)\z/
  HORLOGE = /\Ahorloge-(?:(?<heures>\d{2})(?<minutes>\d{2})|vide)-(?<chiffres>chiffres|nue)\z/
  HEURE_TAPEE = /\A(?<heures>\d{1,2})\s*(?:(?:h|:)\s*(?<minutes>\d{1,2})?)?\s*\z/i

  attr_reader :id, :kind, :picto, :heures, :minutes

  def self.find(id)
    new(id.to_s)
  end

  # Construit l'identifiant d'une figure à partir des paramètres de l'éditeur.
  # Renvoie nil pour toute combinaison qui ne désigne pas une figure valide.
  def self.id_for(kind:, nom: nil, heure: nil, chiffres: true, marge: false)
    id = { "seyes" => "seyes#{'-marge' if marge}",
           "ligne" => LIGNE,
           "picto" => "picto-#{nom}",
           "horloge" => "horloge-#{horloge_code(heure)}-#{chiffres ? 'chiffres' : 'nue'}" }[kind.to_s]
    id if id && valid_id?(id)
  end

  # « 3:15 », « 3h15 », « 15 h 15 » -> « 0315 » (cadran de 12 h) ; vide -> « vide ».
  # Une heure illisible donne un identifiant invalide, donc nil dans `id_for`.
  def self.horloge_code(heure)
    texte = heure.to_s.strip
    return "vide" if texte.empty?

    match = texte.match(HEURE_TAPEE)
    return "invalide" unless match && match[:heures].to_i <= 23 && match[:minutes].to_i <= 59

    heures = match[:heures].to_i % 12
    format("%<heures>02d%<minutes>02d", heures: heures.zero? ? 12 : heures, minutes: match[:minutes].to_i)
  end

  def self.valid_id?(id)
    new(id)
    true
  rescue ActiveRecord::RecordNotFound
    false
  end

  def initialize(id)
    @id = id
    @kind = parse_seyes || (:ligne if id == LIGNE) || parse_picto || parse_horloge ||
            # ActionText transforme cette exception en pièce jointe manquante.
            raise(ActiveRecord::RecordNotFound, "Figure inconnue : #{id}")
  end

  def persisted?
    true
  end

  def ==(other)
    other.is_a?(Figure) && other.id == id
  end
  alias eql? ==

  delegate :hash, to: :id

  def inline?
    kind == :picto
  end

  def content_type
    inline? ? INLINE_CONTENT_TYPE : CONTENT_TYPE
  end

  def to_trix_content_attachment_partial_path
    "figures/editor"
  end

  # Taille et position quand la pièce jointe n'en porte pas : une horloge en
  # pleine largeur occuperait toute la page.
  def presentation_par_defaut
    "taille-25 gauche" if kind == :horloge
  end

  def libelle
    case kind
    when :seyes then "Ligne d'écriture Seyès"
    when :ligne then "Ligne d'écriture"
    when :horloge then horloge_vide? ? "Horloge sans aiguilles" : "Horloge : #{libelle_heure}"
    when :picto then PICTOS.fetch(picto)
    end
  end

  # Ce qu'en garde le texte brut (aperçus, recherche, notifications).
  def attachable_plain_text_representation(_caption = nil)
    %i[seyes ligne].include?(kind) ? "[ligne d'écriture]" : "[#{libelle}]"
  end

  def marge?
    @marge
  end

  def dessin
    DESSINS.fetch(picto)
  end

  def horloge_vide?
    heures.nil?
  end

  def chiffres?
    @chiffres
  end

  def libelle_heure
    format("%<heures>d h %<minutes>02d", heures:, minutes:) unless horloge_vide?
  end

  private

  def parse_seyes
    match = id.match(SEYES) or return
    @marge = match[:marge].present?
    :seyes
  end

  def parse_picto
    match = id.match(PICTO)
    return unless match && PICTOS.key?(match[:nom])

    @picto = match[:nom]
    :picto
  end

  def parse_horloge
    match = id.match(HORLOGE)
    return unless match && horloge_valide?(match)

    @heures = match[:heures]&.to_i
    @minutes = match[:minutes]&.to_i
    @chiffres = match[:chiffres] == "chiffres"
    :horloge
  end

  def horloge_valide?(match)
    return true if match[:heures].nil?

    match[:heures].to_i.between?(1, 12) && match[:minutes].to_i.between?(0, 59)
  end
end
