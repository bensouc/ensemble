# frozen_string_literal: true

# Banc d'essai navigateur pour l'éditeur de tableaux ActionText.
#
#   bin/rails runner scripts/table_editor_browser_check.rb
#
# Voir scripts/support/browser_harness.rb pour le pourquoi de ces bancs.
# Les requêtes d'enregistrement échouent volontairement (pas de serveur) : ce
# qui est vérifié ici, c'est le comportement DOM, le style RENDU et la charge
# utile produite.
require "json"
require "cgi"
require_relative "support/browser_harness"

harness = BrowserHarness::Runner.new("table_editor_harness")

value = harness.sample_table(rows: 2, columns: 2, data: { "0-0" => "Mot", "0-1" => "Nature" }) do |table|
  html = %(<div>Énoncé</div><action-text-attachment sgid="#{table.attachable_sgid}" ) +
         %(content-type="application/octet-stream"></action-text-attachment>)
  ActionText::Content.new(html).to_trix_html.to_s
end

harness.dump_bundle
# La feuille compilée est indispensable : plusieurs bugs de cet éditeur étaient
# des problèmes de spécificité CSS, invisibles si l'on ne vérifie que les classes.
harness.dump_stylesheet("application")
harness.page("index",
             head: %(<title>banc tableaux</title><link rel="stylesheet" href="./application.css">),
             body: <<~HTML)
               <form id="f">
                 <div class="field rt-field" data-controller="rich-text-table table-editor">
                   <input type="hidden" id="content_input" value="#{CGI.escapeHTML(value)}">
                   <trix-editor id="challenge_content" input="content_input" class="trix-content"></trix-editor>
                 </div>
                 <button type="submit">Enregistrer</button>
               </form>
               <script src="./application.js"></script>
             HTML

harness.with_browser do |browser|
  exceptions = []
  browser.on(:exception) { |e, _| exceptions << e.to_s }

  started = Time.now
  browser.go_to(harness.url("index"))
  sleep 2
  elapsed = Time.now - started

  puts "1. la page vit-elle ? (détection de boucle)"
  harness.check "chargée en #{elapsed.round(1)}s et réactive", browser.evaluate("1 + 1") == 2
  harness.check "aucune exception JS", exceptions.empty?
  exceptions.first(3).each { |e| puts "     #{e[0, 160]}" }

  puts "\n2. rendu et hydratation"
  harness.check "4 cellules", browser.evaluate("document.querySelectorAll('.rt-table--editor .rt-cell').length") == 4
  harness.check "toolbar complète", browser.evaluate("document.querySelectorAll('.rt-table__toolbar button').length") >= 12

  puts "\n3. édition d'une cellule"
  cell_bar_hidden = browser.evaluate("getComputedStyle(document.querySelector('.rt-table__bar--cell')).display") == "none"
  browser.at_css(".rt-table--editor .rt-cell").click
  sleep 0.4
  harness.check "la cellule cliquée prend le focus",
                browser.evaluate("document.activeElement.classList.contains('rt-cell')")
  browser.keyboard.type("X")
  sleep 0.4
  harness.check "la saisie s'inscrit",
                browser.evaluate("document.querySelector('.rt-table--editor .rt-cell').textContent").include?("X")

  puts "\n4. le bloc « Cellule » suit-il le focus ?"
  harness.check "masqué tant qu'aucune cellule n'a le focus", cell_bar_hidden
  harness.check "visible une fois la cellule active",
                browser.evaluate("getComputedStyle(document.querySelector('.rt-table__bar--cell')).display") != "none"
  # Les deux rangées doivent démarrer au même endroit : c'est la raison d'être
  # de la grille à deux colonnes de la barre (les libellés partagent la 1re).
  left = JSON.parse(browser.evaluate(<<~JS))
    JSON.stringify(Array.from(document.querySelectorAll('.rt-table__bar'))
      .map(b => b.firstElementChild.getBoundingClientRect().left))
  JS
  harness.check "les deux rangées alignées à gauche (#{left.map { |v| v.round(1) }.join(' / ')})",
                (left[0] - left[1]).abs < 0.5

  puts "\n5. la toolbar principale se met-elle en retrait ?"
  harness.check "toolbar neutralisée pendant l'édition d'une cellule",
                browser.evaluate("document.querySelector('trix-toolbar').classList.contains('rt-tb--table-focus')")
  harness.check "groupes de boutons inertes",
                browser.evaluate("getComputedStyle(document.querySelector('trix-toolbar .trix-button-group')).pointerEvents") == "none"
  harness.check "infobulle explicative posée",
                browser.evaluate("(document.querySelector('trix-toolbar .trix-button-row').getAttribute('title') || '').includes('barre du tableau')")

  puts "\n6. actions de la barre du tableau"
  browser.at_css(".rt-table__toolbar .rt-t-style-b").click
  sleep 0.4
  harness.check "gras appliqué à la cellule",
                browser.evaluate("document.querySelector('.rt-table--editor .rt-cell').classList.contains('rt-c-b')")

  browser.at_css(".rt-table__toolbar .rt-t-align-center").click
  sleep 0.4
  harness.check "alignement centré appliqué",
                browser.evaluate("document.querySelector('.rt-table--editor .rt-cell').classList.contains('rt-al-center')")

  before = browser.evaluate("document.querySelectorAll('.rt-table--editor tr')[0].cells.length")
  browser.at_css(".rt-table__toolbar .rt-t-col-after").click
  sleep 0.4
  harness.check "colonne ajoutée (#{before} -> #{before + 1})",
                browser.evaluate("document.querySelectorAll('.rt-table--editor tr')[0].cells.length") == before + 1

  browser.at_css(".rt-table__toolbar .rt-t-header").click
  sleep 0.4
  harness.check "ligne d'en-tête convertie en th",
                browser.evaluate("document.querySelectorAll('.rt-table--editor th').length").positive?

  # 3e pastille = #F24150, choisie parce qu'elle se distingue nettement de la
  # couleur de texte par défaut (la 1re, #3D3D3D, lui est identique).
  browser.css(".rt-table__toolbar .rt-t-color")[2].click
  sleep 0.4
  harness.check "couleur de texte appliquée à la cellule",
                browser.evaluate("document.querySelector('.rt-table--editor .rt-cell').style.color") == "rgb(242, 65, 80)"

  puts "\n7. le style est-il réellement RENDU ? (et pas seulement posé en classe)"
  style = JSON.parse(browser.evaluate(<<~JS))
    (() => {
      const s = getComputedStyle(document.querySelector('.rt-table--editor .rt-cell'))
      return JSON.stringify({ textAlign: s.textAlign, fontWeight: s.fontWeight })
    })()
  JS
  puts "  #{style}"
  harness.check "alignement effectivement centré", style["textAlign"] == "center"
  harness.check "gras effectivement appliqué", style["fontWeight"].to_i >= 700

  puts "\n8. charge utile envoyée au serveur"
  payload = JSON.parse(browser.evaluate(<<~JS))
    (() => {
      const c = window.Stimulus.getControllerForElementAndIdentifier(document.querySelector('.rt-field'), 'table-editor')
      return JSON.stringify(c.readState(document.querySelector('.rt-table--editor')))
    })()
  JS
  puts "  #{payload.to_json[0, 220]}"
  harness.check "dimensions cohérentes", payload["rows"] == 2 && payload["columns"] == 3
  harness.check "en-tête transmis", payload["header_row"] == true
  harness.check "style de cellule transmis", payload.dig("cell_styles", "0-0") == ["b"]
  harness.check "alignement transmis", payload["col_aligns"][0] == "center"
  harness.check "texte saisi transmis", payload.dig("data", "0-0").to_s.include?("X")
  harness.check "couleur de cellule transmise", payload.dig("cell_colors", "0-0") == "#F24150"

  puts "\n9. toujours vivant après toutes les opérations"
  harness.check "page réactive", browser.evaluate("2 + 2") == 4
  harness.check "aucune exception JS", exceptions.empty?
end

harness.report!
