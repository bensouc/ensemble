# frozen_string_literal: true

# Parité de rendu des tableaux entre l'éditeur et le PDF.
#
#   bin/rails runner scripts/table_pdf_parity_check.rb
#
# Le PDF a sa propre feuille (`pdf.scss`, autonome, sans dépendance réseau) :
# les styles de tableau y avaient été dupliqués, puis les deux rendus ont
# divergé — plus de fond d'en-tête, ni alignement, ni style de cellule côté PDF.
# Depuis, `pdf.scss` importe `trix/tables`, la partie partagée. Ce script vérifie
# que la parité tient, en rendant le MÊME balisage sous les deux feuilles et en
# comparant les styles calculés par un vrai navigateur.
require "ferrum"
require "json"

HARNESS = Rails.root.join("tmp/table_pdf_parity")
FileUtils.mkdir_p(HARNESS)

# Un tableau qui exerce tout : en-tête, alignement, styles de cellule.
markup = nil
ActiveRecord::Base.transaction do
  table = Table.create!(
    rows: 2, columns: 3, header_row: true,
    data: { "0-0" => "Mot", "0-1" => "Nature", "1-0" => "chat" },
    cell_styles: { "1-0" => %w[b i] },
    col_aligns: %w[left center right]
  )
  markup = ApplicationController.render(partial: "tables/table", locals: { table: table }, formats: [:html])
  raise ActiveRecord::Rollback
end

%w[application pdf].each do |sheet|
  File.write(HARNESS.join("#{sheet}.css"), Rails.application.assets["#{sheet}.css"].to_s)
  File.write(HARNESS.join("#{sheet}.html"), <<~HTML)
    <!doctype html><html lang="fr"><head><meta charset="utf-8">
    <link rel="stylesheet" href="./#{sheet}.css"></head>
    <body><div class="cont-challenge"><div class="trix-content">#{markup}</div></div></body></html>
  HTML
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

browser = Ferrum::Browser.new(headless: true, timeout: 20)
results = {}
begin
  %w[application pdf].each do |sheet|
    browser.go_to("file://#{HARNESS.join("#{sheet}.html")}")
    sleep 0.6
    results[sheet] = JSON.parse(browser.evaluate(PROBE))
  end
ensure
  browser.quit
end

failures = []
results["application"].each do |zone, expected|
  actual = results["pdf"][zone]
  expected.each do |prop, value|
    same = actual[prop] == value
    failures << "#{zone}.#{prop}" unless same
    next if same

    puts format("  %-28s éditeur=%-22s pdf=%s", "#{zone}.#{prop}", value, actual[prop])
  end
end

puts "\nRéférence éditeur (en-tête) : #{results['application']['headerCell'].slice('backgroundColor', 'fontWeight', 'borderBottomWidth')}"
puts "Référence éditeur (cellule) : #{results['application']['styledCell'].slice('fontWeight', 'fontStyle')}"
puts "Alignement 3e colonne       : #{results['application']['headerRight']['textAlign']}"

if failures.empty?
  puts "\nParité éditeur / PDF : identique sur toutes les propriétés contrôlées."
else
  puts "\n#{failures.size} écart(s) : #{failures.join(', ')}"
end
exit(failures.empty? ? 0 : 1)
