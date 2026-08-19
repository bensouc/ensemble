# frozen_string_literal: true

# Banc d'essai navigateur pour l'éditeur de tableaux ActionText.
#
#   bin/rails runner scripts/table_editor_browser_check.rb
#
# Pourquoi ce script existe : l'éditeur de tableaux vit à l'intérieur d'une
# pièce jointe Trix, et l'essentiel des bugs y vient de l'interaction avec Trix
# lui-même — sanitisation du balisage, re-rendu de la pièce jointe, gestion du
# focus. Rien de tout cela ne se voit dans une spec Ruby, et le diagnostic à
# l'aveugle coûte très cher (on y a notamment laissé passer une boucle infinie
# qui figeait le navigateur).
#
# Le banc charge le vrai bundle et le vrai Trix dans un Chrome piloté par
# Ferrum, sur une page autonome — ni serveur, ni authentification, ni base au
# moment du test. Les requêtes d'enregistrement échouent donc volontairement :
# ce qui est vérifié ici, c'est le comportement DOM et la charge utile produite.
require "ferrum"
require "json"
require "cgi"

HARNESS = Rails.root.join("tmp/table_editor_harness")
FileUtils.mkdir_p(HARNESS)

# 1. Un tableau de test, et la valeur Trix telle que le formulaire la produirait.
value = nil
ActiveRecord::Base.transaction do
  table = Table.create!(rows: 2, columns: 2, data: { "0-0" => "Mot", "0-1" => "Nature" })
  html = %(<div>Énoncé</div><action-text-attachment sgid="#{table.attachable_sgid}" ) +
         %(content-type="application/octet-stream"></action-text-attachment>)
  value = ActionText::Content.new(html).to_trix_html.to_s
  raise ActiveRecord::Rollback
end

# 2. Le bundle, en IIFE : une page file:// ne peut pas charger de module ES.
build = <<~JS
  const esbuild = require(#{Rails.root.join("node_modules/esbuild").to_s.inspect})
  const rails = require(#{Rails.root.join("node_modules/esbuild-rails").to_s.inspect})
  esbuild.build({
    entryPoints: [#{Rails.root.join("app/javascript/application.js").to_s.inspect}],
    bundle: true, format: 'iife', outfile: #{HARNESS.join("application.js").to_s.inspect},
    absWorkingDir: #{Rails.root.to_s.inspect}, plugins: [rails()], logLevel: 'error',
  }).catch(e => { console.error(e); process.exit(1) })
JS
File.write(HARNESS.join("build.js"), build)
abort("échec de la compilation du bundle") unless system("node", HARNESS.join("build.js").to_s)

# La feuille compilée est nécessaire : plusieurs bugs de cet éditeur étaient des
# problèmes de spécificité CSS, invisibles si l'on ne vérifie que les classes.
css = Rails.application.assets["application.css"].to_s
File.write(HARNESS.join("application.css"), css)

File.write(HARNESS.join("index.html"), <<~HTML)
  <!doctype html><html lang="fr"><head><meta charset="utf-8"><title>banc tableaux</title>
  <link rel="stylesheet" href="./application.css"></head><body>
    <form id="f">
      <div class="field rt-field" data-controller="rich-text-table table-editor">
        <input type="hidden" id="content_input" value="#{CGI.escapeHTML(value)}">
        <trix-editor id="challenge_content" input="content_input" class="trix-content"></trix-editor>
      </div>
      <button type="submit">Enregistrer</button>
    </form>
    <script src="./application.js"></script>
  </body></html>
HTML

# 3. Pilotage.
failures = []
browser = Ferrum::Browser.new(headless: true, timeout: 20)
exceptions = []
browser.on(:exception) { |e, _| exceptions << e.to_s }

def check(failures, label, condition)
  puts format("  %-52s %s", label, condition ? "OK" : "ÉCHEC")
  failures << label unless condition
end

begin
  started = Time.now
  browser.go_to("file://#{HARNESS.join('index.html')}")
  sleep 2
  elapsed = Time.now - started

  puts "1. la page vit-elle ? (détection de boucle)"
  check failures, "chargée en #{elapsed.round(1)}s et réactive", browser.evaluate("1 + 1") == 2
  check failures, "aucune exception JS", exceptions.empty?
  exceptions.first(3).each { |e| puts "     #{e[0, 160]}" }

  puts "\n2. rendu et hydratation"
  check failures, "4 cellules", browser.evaluate("document.querySelectorAll('.rt-table--editor .rt-cell').length") == 4
  check failures, "toolbar complète", browser.evaluate("document.querySelectorAll('.rt-table__toolbar button').length") >= 12

  puts "\n3. édition d'une cellule"
  @cell_bar_hidden_before =
    browser.evaluate("getComputedStyle(document.querySelector('.rt-table__bar--cell')).display") == "none"
  browser.at_css(".rt-table--editor .rt-cell").click
  sleep 0.4
  check failures, "la cellule cliquée prend le focus",
        browser.evaluate("document.activeElement.classList.contains('rt-cell')")
  browser.keyboard.type("X")
  sleep 0.4
  check failures, "la saisie s'inscrit",
        browser.evaluate("document.querySelector('.rt-table--editor .rt-cell').textContent").include?("X")

  puts "\n4. le bloc « Cellule » suit-il le focus ?"
  check failures, "masqué tant qu'aucune cellule n'a le focus", @cell_bar_hidden_before
  check failures, "visible une fois la cellule active",
        browser.evaluate("getComputedStyle(document.querySelector('.rt-table__bar--cell')).display") != "none"

  puts "\n5. la toolbar principale se met-elle en retrait ?"
  check failures, "toolbar neutralisée pendant l'édition d'une cellule",
        browser.evaluate("document.querySelector('trix-toolbar').classList.contains('rt-tb--table-focus')")
  check failures, "groupes de boutons inertes",
        browser.evaluate("getComputedStyle(document.querySelector('trix-toolbar .trix-button-group')).pointerEvents") == "none"
  check failures, "infobulle explicative posée",
        browser.evaluate("(document.querySelector('trix-toolbar .trix-button-row').getAttribute('title') || '').includes('barre du tableau')")

  puts "\n6. actions de la toolbar du tableau"
  browser.at_css(".rt-table__toolbar .rt-t-style-b").click
  sleep 0.4
  check failures, "gras appliqué à la cellule",
        browser.evaluate("document.querySelector('.rt-table--editor .rt-cell').classList.contains('rt-c-b')")

  browser.at_css(".rt-table__toolbar .rt-t-align-center").click
  sleep 0.4
  check failures, "alignement centré appliqué",
        browser.evaluate("document.querySelector('.rt-table--editor .rt-cell').classList.contains('rt-al-center')")

  before = browser.evaluate("document.querySelectorAll('.rt-table--editor tr')[0].cells.length")
  browser.at_css(".rt-table__toolbar .rt-t-col-after").click
  sleep 0.4
  check failures, "colonne ajoutée (#{before} -> #{before + 1})",
        browser.evaluate("document.querySelectorAll('.rt-table--editor tr')[0].cells.length") == before + 1

  browser.at_css(".rt-table__toolbar .rt-t-header").click
  sleep 0.4
  check failures, "ligne d'en-tête convertie en th",
        browser.evaluate("document.querySelectorAll('.rt-table--editor th').length").positive?

  # 3e pastille = #F24150, choisie parce qu'elle se distingue nettement de la
  # couleur de texte par défaut (la 1re, #3D3D3D, lui est identique).
  browser.css(".rt-table__toolbar .rt-t-color")[2].click
  sleep 0.4
  check failures, "couleur de texte appliquée à la cellule",
        browser.evaluate("document.querySelector('.rt-table--editor .rt-cell').style.color") == "rgb(242, 65, 80)"

  puts "\n7. le style est-il réellement RENDU ? (et pas seulement posé en classe)"
  computed = browser.evaluate(<<~JS)
    (() => {
      const c = document.querySelector('.rt-table--editor .rt-cell')
      const s = getComputedStyle(c)
      return JSON.stringify({ textAlign: s.textAlign, fontWeight: s.fontWeight })
    })()
  JS
  style = JSON.parse(computed)
  puts "  #{computed}"
  check failures, "alignement effectivement centré", style["textAlign"] == "center"
  check failures, "gras effectivement appliqué", style["fontWeight"].to_i >= 700

  puts "\n8. charge utile envoyée au serveur"
  state = browser.evaluate(<<~JS)
    (() => {
      const c = window.Stimulus.getControllerForElementAndIdentifier(document.querySelector('.rt-field'), 'table-editor')
      return JSON.stringify(c.readState(document.querySelector('.rt-table--editor')))
    })()
  JS
  payload = JSON.parse(state)
  puts "  #{state[0, 220]}"
  check failures, "dimensions cohérentes", payload["rows"] == 2 && payload["columns"] == 3
  check failures, "en-tête transmis", payload["header_row"] == true
  check failures, "style de cellule transmis", payload.dig("cell_styles", "0-0") == ["b"]
  check failures, "alignement transmis", payload["col_aligns"][0] == "center"
  check failures, "texte saisi transmis", payload.dig("data", "0-0").to_s.include?("X")
  check failures, "couleur de cellule transmise", payload.dig("cell_colors", "0-0") == "#F24150"

  puts "\n9. toujours vivant après toutes les opérations"
  check failures, "page réactive", browser.evaluate("2 + 2") == 4
  check failures, "aucune exception JS", exceptions.empty?
ensure
  browser.quit
end

puts "\n#{failures.empty? ? 'Tout est vert.' : "#{failures.size} échec(s) : #{failures.join(', ')}"}"
exit(failures.empty? ? 0 : 1)
