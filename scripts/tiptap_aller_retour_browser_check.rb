# frozen_string_literal: true

# Banc aller-retour de l'éditeur d'énoncé (TipTap), sur TOUS les énoncés de la base.
#
#   bin/rails runner scripts/tiptap_aller_retour_browser_check.rb
#
# Pour chaque énoncé : ce que l'éditeur reçoit (`EditeurTiptap.contenu_initial`,
# tableaux maison convertis) passe dans TipTap, ressort, est réenregistré comme
# le ferait ActionText, puis rendu comme dans l'app. On le compare, dans Chrome,
# styles calculés à l'appui, à ce que donnerait le même ouvrir-enregistrer SANS
# éditeur : Rails à lui seul modifie déjà certains corps (il ajoute
# `previewable` aux images), ce n'est pas à TipTap d'en répondre.
#
# Comparés caractère par caractère : texte, gras, italique, souligné, couleurs,
# taille, alignement ; puis retours à la ligne, positions, et éléments (images,
# tableaux, listes, titres, liens).
#
# Sur la base de dev (copie de la prod), les sgid sont signés avec la clé de la
# prod : ceux des tableaux sont re-signés ici, sinon ni l'avant ni l'après ne
# les liraient et la conversion ne serait pas éprouvée.
require "json"
require_relative "support/browser_harness"

harness = BrowserHarness::Runner.new("tiptap_aller_retour")
harness.dump_bundle("aller_retour.js", entry: "scripts/support/tiptap_aller_retour.js")
harness.dump_stylesheet("application")
harness.page("tiptap", head: "", body: %(<script src="./aller_retour.js"></script>))
# Réenregistré, un paragraphe prend exprès la mise en page de l'éditeur (`rt-p` :
# interligne 1,4, collé au suivant, ligne vide visible). On la neutralise côté
# « après » pour ne juger que ce que l'éditeur conserve. La ligne vide, au premier
# niveau seulement : la case vide d'un tableau avait déjà la sienne.
NEUTRE = <<~CSS
  #b .rt-p { line-height: inherit; }
  #b .trix-content > .rt-p + .rt-p, #b .rt-colonne > .rt-p + .rt-p { margin-top: 0.7em; }
  #b .trix-content > .rt-p:empty::before { content: none; }
CSS
harness.page("comparaison",
             head: %(<link rel="stylesheet" href="./application.css"><style>#{NEUTRE}</style>),
             body: <<~HTML)
               <div id="a" class="rt-field" style="width:760px"></div>
               <div id="b" class="rt-field" style="width:760px"></div>
               <script>#{Rails.root.join('scripts/support/tiptap_signature.js').read}</script>
             HTML

GID = %r{gid://[A-Za-z0-9_-]+/([A-Za-z0-9_:]+)/(\d+)}

# Re-signe en local le sgid d'un tableau, lu sans vérification (deux formats
# coexistent en base : Base64(Marshal) et Base64(JSON)).
def resigne(html)
  html.gsub(/sgid="([^"]+)"/) do
    match = sgid_brut(Regexp.last_match(1)).match(GID)
    table = match && match[1] == "Table" && Table.find_by(id: match[2])
    table ? %(sgid="#{table.attachable_sgid}") : Regexp.last_match(0)
  end
end

def sgid_brut(sgid)
  Base64.urlsafe_decode64(sgid.split("--").first).force_encoding("BINARY")
rescue ArgumentError
  ""
end

# Une image de la prod ne se chargerait pas (et ne doit pas l'être) : on ôte les
# adresses, des deux côtés.
def sans_images(html) = html.gsub(/(<img\b[^>]*?)\ssrc="[^"]*"/, '\1')

def rendu(html) = sans_images(ActionText::Content.new(html, canonicalize: true).to_rendered_html_with_layout)

Rails.logger.level = :error
textes = ActionText::RichText.where(record_type: "Challenge").order(:record_id).to_a.reject { |t| t.body.to_html.strip.empty? }
puts "Énoncés : #{textes.size}"

resultats = []
harness.with_browser do |browser|
  tiptap = browser.create_page
  tiptap.go_to(harness.url("tiptap"))
  sleep 1
  compare = browser.create_page
  compare.go_to(harness.url("comparaison"))
  sleep 1

  textes.each_slice(50) do |lot|
    corps = lot.map { |t| ActionText::Content.new(resigne(t.body.to_html)) }
    entrees = corps.map { |c| EditeurTiptap.contenu_initial(ActionText::RichText.new(body: c)) }
    sorties = tiptap.evaluate("(function(l){ return l.map(function(h){ try { return window.allerRetour(h) } " \
                              "catch(e) { return 'ERREUR:' + e.message } }) })(#{entrees.to_json})")

    paires = lot.each_with_index.map do |texte, i|
      next { "id" => texte.record_id, "erreur" => sorties[i] } if sorties[i].start_with?("ERREUR:")

      { "id" => texte.record_id, "avant" => rendu(corps[i].to_trix_html), "apres" => rendu(sorties[i]) }
    end
    a_comparer = paires.reject { |p| p["erreur"] }
    verdicts = compare.evaluate("(function(l){ return l.map(function(p){ return comparer(p.avant, p.apres) }) })" \
                                "(#{a_comparer.map { |p| p.slice('avant', 'apres') }.to_json})")
    a_comparer.zip(verdicts).each { |p, v| resultats << v.merge("id" => p["id"]) }
    resultats.concat(paires.select { |p| p["erreur"] })
  end
end

categories = { "texte" => "texte", "format" => "mise en forme", "lignes" => "retours à la ligne",
               "elements" => "images, tableaux, listes, titres", "espacement" => "espacement" }
puts "\nAller-retour de #{resultats.size} énoncés dans l'éditeur"
erreurs = resultats.select { |r| r["erreur"] }
harness.check "aucune erreur de l'éditeur", erreurs.empty?
erreurs.first(3).each { |r| puts "     énoncé #{r['id']} : #{r['erreur'][0, 140]}" }
categories.each do |cle, libelle|
  ecarts = resultats.reject { |r| r["erreur"] || r[cle] }
  compares = resultats.size - erreurs.size
  harness.check "#{libelle} identiques (#{compares - ecarts.size}/#{compares})", ecarts.empty?
  ecarts.first(3).each do |r|
    puts "     énoncé #{r['id']} : #{r['detail'] || "hauteur #{r['hauteurAvant']} -> #{r['hauteurApres']}"}"
  end
end
harness.report!
