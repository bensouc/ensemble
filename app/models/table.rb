# frozen_string_literal: true

# Tableau éditable inséré dans un champ ActionText (Trix) via ActionText::Attachable.
#
# Format de `data` (inchangé, historique) : { "<ligne>-<colonne>" => "texte" }.
# La grille est creuse : une cellule jamais éditée est absente du hash.
#
# Les colonnes de mise en forme (header_row, col_aligns, cell_styles) sont
# toutes optionnelles : un tableau créé avant leur introduction se rend à
# l'identique.
class Table < ApplicationRecord
  include GlobalID::Identification
  include ActionText::Attachable

  MAX_ROWS = 60
  MAX_COLUMNS = 20
  MAX_CELL_LENGTH = 2_000
  ALIGNMENTS = %w[left center right].freeze
  # Format d'une clé de grille creuse : "<ligne>-<colonne>".
  CELL_KEY = /\A\d+-\d+\z/
  # Les trois grilles creuses, décalées et purgées ensemble.
  SPARSE_ATTRIBUTES = %i[data cell_styles cell_colors].freeze
  CELL_STYLE_FLAGS = %w[b i u].freeze

  # La couleur d'une cellule est écrite en `style` inline : c'est le seul canal
  # qui accepte une valeur libre à l'intérieur d'une pièce jointe Trix (son
  # sanitizer ne conserve que style/href/src/width/height/class/language).
  # On s'en tient donc à une liste blanche, plutôt qu'à une validation de
  # format : aucune valeur arbitraire ne peut atteindre l'attribut.
  # Mêmes teintes que le nuancier de la toolbar principale (trix-config.js).
  TEXT_COLORS = %w[#3D3D3D #9C9C9C #F24150 #C44003 #E67E22 #4CAF50 #167FFB #7C5CE7].freeze

  def to_trix_content_attachment_partial_path
    "tables/editor"
  end

  # --- Lecture ---------------------------------------------------------------

  def cell(row, col)
    data[key(row, col)]
  end

  def align_for(col)
    align = Array(col_aligns)[col]
    ALIGNMENTS.include?(align) ? align : "left"
  end

  def color_for(row, col)
    color = cell_colors.is_a?(Hash) ? cell_colors[key(row, col)] : nil
    color if TEXT_COLORS.include?(color)
  end

  def styles_for(row, col)
    Array(cell_styles.is_a?(Hash) ? cell_styles[key(row, col)] : nil) & CELL_STYLE_FLAGS
  end

  def header_row?
    header_row == true
  end

  # --- Opérations structurelles ---------------------------------------------
  # Elles décalent réellement les données, contrairement à l'ancien
  # "supprime la dernière ligne" qui laissait des orphelins dans `data`.

  def insert_row!(at)
    at = at.to_i.clamp(0, rows)
    return self if rows >= MAX_ROWS

    remap! { |r, c| r >= at ? [r + 1, c] : [r, c] }
    self.rows += 1
    save!
    self
  end

  def delete_row!(at)
    at = at.to_i
    return self if rows <= 1 || !at.between?(0, rows - 1)

    remap! { |r, c| r == at ? nil : [r > at ? r - 1 : r, c] }
    self.rows -= 1
    save!
    self
  end

  def insert_column!(at)
    at = at.to_i.clamp(0, columns)
    return self if columns >= MAX_COLUMNS

    remap! { |r, c| c >= at ? [r, c + 1] : [r, c] }
    self.col_aligns = Array(col_aligns).dup.insert(at, "left").first(MAX_COLUMNS)
    self.columns += 1
    save!
    self
  end

  def delete_column!(at)
    at = at.to_i
    return self if columns <= 1 || !at.between?(0, columns - 1)

    remap! { |r, c| c == at ? nil : [r, c > at ? c - 1 : c] }
    self.col_aligns = Array(col_aligns).dup.tap { |a| a.delete_at(at) }
    self.columns -= 1
    save!
    self
  end

  def write_cell!(cell_key, value)
    return self unless cell_key.to_s.match?(/\A\d+-\d+\z/)

    data[cell_key.to_s] = value.to_s.first(MAX_CELL_LENGTH)
    save!
    self
  end

  # Remplace l'état complet du tableau en une seule requête (chemin utilisé par
  # l'éditeur : toutes les frappes d'un même passage sont regroupées).
  def replace!(raw_attrs)
    # symbolize_keys est volontairement peu profond : les clés de `data`
    # ("0-1", "2-3") doivent rester des String.
    attrs = raw_attrs.symbolize_keys
    self.rows    = int_within(attrs[:rows], 1, MAX_ROWS, rows)
    self.columns = int_within(attrs[:columns], 1, MAX_COLUMNS, columns)
    self.header_row  = to_boolean(attrs[:header_row]) if attrs.key?(:header_row)
    self.data        = sanitized_data(attrs.fetch(:data, data))
    self.cell_styles = sanitized_cell_styles(attrs.fetch(:cell_styles, cell_styles))
    self.cell_colors = sanitized_cell_colors(attrs.fetch(:cell_colors, cell_colors))
    self.col_aligns  = sanitized_aligns(attrs.fetch(:col_aligns, col_aligns)).first(columns)
    save!
    self
  end

  # Copie persistée du tableau, mise en forme comprise.
  #
  # Nommée explicitement : la version précédente s'appelait `clone` et écrasait
  # donc `Object#clone`, dont la sémantique Ruby est tout autre (copie
  # superficielle, non persistée).
  def duplicate
    dup.tap(&:save!)
  end

  private

  def key(row, col)
    "#{row}-#{col}"
  end

  # Réécrit toutes les clés de `data` et `cell_styles` via le bloc fourni.
  # Le bloc reçoit [row, col] et renvoie la nouvelle position, ou nil pour supprimer.
  def remap!(&block)
    SPARSE_ATTRIBUTES.each { |name| public_send(:"#{name}=", remap_hash(public_send(name), &block)) }
  end

  def remap_hash(hash)
    return {} unless hash.is_a?(Hash)

    hash.each_with_object({}) do |(cell_key, value), result|
      next unless cell_key.to_s.match?(CELL_KEY)

      row, col = cell_key.to_s.split("-", 2).map(&:to_i)
      position = yield(row, col)
      result[key(*position)] = value if position
    end
  end

  # Un seul parcours par grille : format de clé, bornes et filtre de valeur.
  # Auparavant chaque hash était reconstruit deux fois, avec deux notions
  # distinctes de « clé valide » à garder cohérentes.
  def rebuild_cells(hash)
    return {} unless hash.is_a?(Hash)

    hash.each_with_object({}) do |(cell_key, raw), result|
      next unless cell_key.to_s.match?(CELL_KEY)

      row, col = cell_key.to_s.split("-", 2).map(&:to_i)
      next unless row < rows && col < columns

      value = yield(raw)
      result[key(row, col)] = value unless value.nil?
    end
  end

  def sanitized_data(incoming)
    rebuild_cells(incoming) { |value| value.to_s.first(MAX_CELL_LENGTH).presence }
  end

  def sanitized_cell_styles(incoming)
    rebuild_cells(incoming) { |flags| (Array(flags).map(&:to_s) & CELL_STYLE_FLAGS).presence }
  end

  def sanitized_cell_colors(incoming)
    rebuild_cells(incoming) { |color| color.to_s.upcase.presence_in(TEXT_COLORS) }
  end

  def sanitized_aligns(incoming)
    Array(incoming).first(MAX_COLUMNS).map { |a| ALIGNMENTS.include?(a.to_s) ? a.to_s : "left" }
  end

  def int_within(value, min, max, fallback)
    return fallback if value.nil?

    value.to_i.clamp(min, max)
  end

  def to_boolean(value)
    ActiveModel::Type::Boolean.new.cast(value) || false
  end
end
