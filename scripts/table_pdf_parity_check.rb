# frozen_string_literal: true

# Parité de rendu des tableaux entre l'éditeur et le PDF.
#
#   bin/rails runner scripts/table_pdf_parity_check.rb
#
# Le PDF a sa propre feuille (`pdf.scss`, autonome, sans dépendance réseau) :
# les styles de tableau y avaient été dupliqués, puis les deux rendus ont
# divergé — plus de fond d'en-tête, ni alignement, ni style de cellule côté PDF.
# Depuis, `pdf.scss` importe `trix/tables`, la partie partagée. Ce script rend le
# MÊME balisage sous les deux feuilles et compare les styles calculés par un
# vrai navigateur.
require "json"
require_relative "support/browser_harness"

SHEETS = %w[application pdf].freeze

harness = BrowserHarness::Runner.new("table_pdf_parity")

# Un tableau qui exerce tout : en-tête, alignement, styles et couleur de cellule.
markup = harness.sample_table(
  rows: 2, columns: 3, header_row: true,
  data: { "0-0" => "Mot", "0-1" => "Nature", "1-0" => "chat" },
  cell_styles: { "1-0" => %w[b i] },
  cell_colors: { "1-0" => "#F24150" },
  col_aligns: %w[left center right]
) { |table| ApplicationController.render(partial: "tables/table", locals: { table: table }, formats: [:html]) }

SHEETS.each do |sheet|
  harness.dump_stylesheet(sheet)
  harness.page(sheet,
               head: %(<link rel="stylesheet" href="./#{sheet}.css">),
               body: %(<div class="cont-challenge"><div class="trix-content">#{markup}</div></div>))
end

# Propriétés qui portent la différence visible entre les deux rendus.
PROBE = <<~JS
  (() => {
    const pick = (el) => {
      if (!el) return null
      const s = getComputedStyle(el)
      return {
        backgroundColor: s.backgroundColor, color: s.color,
        fontWeight: s.fontWeight, fontStyle: s.fontStyle,
        textAlign: s.textAlign, padding: s.padding,
        borderTopWidth: s.borderTopWidth, borderBottomWidth: s.borderBottomWidth,
        borderLeftWidth: s.borderLeftWidth, borderRightWidth: s.borderRightWidth,
        borderTopColor: s.borderTopColor
      }
    }
    const rows = document.querySelectorAll('.rt-table__grid tr')
    return JSON.stringify({
      headerCell:   pick(rows[0].cells[0]),
      headerRight:  pick(rows[0].cells[2]),
      styledCell:   pick(rows[1].cells[0]),
      centeredCell: pick(rows[1].cells[1])
    })
  })()
JS

results = {}
harness.with_browser do |browser|
  SHEETS.each do |sheet|
    browser.go_to(harness.url(sheet))
    sleep 0.6
    results[sheet] = JSON.parse(browser.evaluate(PROBE))
  end
end

results["application"].each do |zone, expected|
  actual = results["pdf"][zone]
  expected.each do |property, value|
    harness.check("#{zone}.#{property}", actual[property] == value) unless actual[property] == value
  end
end

puts "Référence éditeur (en-tête) : #{results['application']['headerCell'].slice('backgroundColor', 'fontWeight', 'borderBottomWidth')}"
puts "Référence éditeur (cellule) : #{results['application']['styledCell'].slice('fontWeight', 'fontStyle', 'color')}"
puts "Alignement 3e colonne       : #{results['application']['headerRight']['textAlign']}"
harness.report!
