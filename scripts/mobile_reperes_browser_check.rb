# frozen_string_literal: true

# Banc d'essai des repères de l'écran mobile, et du geste d'ouverture d'un
# domaine.
#
#   bin/rails runner scripts/mobile_reperes_browser_check.rb
#
# Voir scripts/support/browser_harness.rb pour le pourquoi de ces bancs.
#
# Trois choses s'y vérifient, qu'un coup d'œil sur un seul navigateur ne tranche
# pas :
#
#   — le point « messages non lus » tient sur son icône, et non à côté. Il était
#     posé en `position: relative` avec deux nombres en pixels, donc calé sur la
#     boîte de ligne de l'icône : il tombait ailleurs dès que la police servie
#     changeait, ce qui arrive sur iPhone ;
#   — l'anneau d'une pastille est centré sur son disque et tient dans sa boîte.
#     Il se dimensionnait par `inset` sur les quatre côtés, ce qu'un `<svg>` —
#     élément remplacé — n'arbitre pas de la même façon d'un moteur à l'autre ;
#   — ouvrir un domaine amène ses compétences dans l'écran. Ouvert depuis le bas
#     de la liste, il les faisait apparaître sous le pli.
require_relative "support/browser_harness"

IPHONE_12_MINI = { width: 375, height: 812 }.freeze

def boite(page, selecteur)
  page.evaluate(<<~JS)
    (() => {
      const e = document.querySelector("#{selecteur}");
      if (!e) return null;
      const r = e.getBoundingClientRect();
      return { l: r.left, t: r.top, w: r.width, h: r.height,
               cx: r.left + r.width / 2, cy: r.top + r.height / 2 };
    })()
  JS
end

# Le point doit se poser SUR l'icône — dans sa boîte, au bord haut-droit — et
# non flotter à côté d'elle.
def etape_point_messages(harness, page, portee)
  puts "\n— Le point « messages non lus » tient sur son icône (#{portee.strip})"
  point = boite(page, "#{portee}.bullet-chat")
  icone = boite(page, "#{portee}.icone-messages")

  harness.check("il est ancré sur l'icône, pas sur la boîte de ligne",
                calage(page, portee) == "absolute")
  verifier_position_du_point(harness, point, icone)
  verifier_taille_du_point(harness, point, icone)
end

def verifier_position_du_point(harness, point, icone)
  bord = "#{icone['l'].round}..#{(icone['l'] + icone['w']).round}"
  harness.check("son centre tombe dans l'icône (#{point['cx'].round},#{point['cy'].round} dans #{bord})",
                dedans?(point, icone))
  harness.check("il se tient en haut à droite, pas au milieu du dessin",
                haut_droite?(point, icone))
end

def haut_droite?(point, icone)
  point["cx"] > icone["l"] + (icone["w"] * 0.5) &&
    point["cy"] < icone["t"] + (icone["h"] * 0.5)
end

# La boîte de l'icône fait 0,75em de large : un point qui en occuperait plus de
# la moitié cesserait d'être une marque pour devenir une pièce du dessin.
def verifier_taille_du_point(harness, point, icone)
  harness.check("il est proportionné à l'icône (#{point['w'].round(1)} pour #{icone['w'].round(1)})",
                point["w"].between?(icone["w"] * 0.2, icone["w"] * 0.5))
end

def calage(page, portee)
  page.evaluate(%(getComputedStyle(document.querySelector("#{portee}.bullet-chat")).position))
end

def dedans?(point, icone)
  point["cx"].between?(icone["l"], icone["l"] + icone["w"]) &&
    point["cy"].between?(icone["t"], icone["t"] + icone["h"])
end

# L'anneau déborde du disque de trois huitièmes de diamètre de chaque côté, et
# reste centré dessus. Sa boîte doit être donnée en taille, pas déduite de
# quatre décalages : un `<svg>` posé en absolu avec `inset` seul n'a que sa
# taille intrinsèque à leur opposer, et les moteurs tranchent différemment.
def etape_anneau(harness, page)
  puts "\n— L'anneau est centré sur son disque"
  mesures = mesurer_anneaux(page)

  raise "aucun anneau visible à mesurer" if mesures.empty?

  verifier_boite(harness, mesures)
  verifier_rapport(harness, mesures)
  verifier_fleche(harness, page)
end

def verifier_boite(harness, mesures)
  harness.check("sa boîte a une taille propre, pas quatre décalages",
                mesures.none? { |m| [m["largeurDeclaree"], m["hauteurDeclaree"]].include?("auto") })
  harness.check("il est centré sur le disque, à toutes les tailles",
                mesures.all? { |m| m["ecartX"].abs < 0.5 && m["ecartY"].abs < 0.5 })
end

def verifier_rapport(harness, mesures)
  rapports = mesures.map { |m| m["rapport"].round(2) }.uniq
  harness.check("il réclame 1,75 fois le disque (#{rapports.inspect})",
                mesures.all? { |m| (m["rapport"] - 1.75).abs < 0.01 })
end

def mesurer_anneaux(page)
  page.evaluate(<<~JS)
    Array.from(document.querySelectorAll(".eval_bull")).map((b) => {
      const s = b.querySelector("svg.eval-anneau");
      if (!s) return null;
      const rb = b.getBoundingClientRect(), rs = s.getBoundingClientRect();
      // Les domaines fermés ont des boîtes nulles : rien à y mesurer.
      if (rb.width === 0) return null;
      const cs = getComputedStyle(s);
      return { statut: b.className, largeurDeclaree: cs.width, hauteurDeclaree: cs.height,
               ecartX: (rs.left + rs.width / 2) - (rb.left + rb.width / 2),
               ecartY: (rs.top + rs.height / 2) - (rb.top + rb.height / 2),
               rapport: rs.width / rb.width };
    }).filter(Boolean)
  JS
end

# La pointe s'écarte du rayon de son arc : sa barbe extérieure passe hors du
# cercle. Elle doit rester dans la boîte, sinon l'anneau entier paraît posé de
# travers sur son disque.
def verifier_fleche(harness, page)
  debords = page.evaluate(<<~JS)
    Array.from(document.querySelectorAll("svg.eval-anneau"))
      .filter((s) => s.getBoundingClientRect().width > 0)
      .flatMap((s) =>
      Array.from(s.querySelectorAll("path"))
        .filter((p) => getComputedStyle(p).display !== "none")
        .map((p) => {
          const bb = p.getBBox();
          const trait = parseFloat(getComputedStyle(p).strokeWidth) / 2;
          return { min: Math.min(bb.x, bb.y) - trait,
                   max: Math.max(bb.x + bb.width, bb.y + bb.height) + trait };
        }))
  JS
  harness.check("la flèche reste dans la boîte de l'anneau",
                debords.all? { |d| d["min"] >= -0.01 && d["max"] <= 42.01 })
end

# Ouvrir un domaine placé en bas de la liste faisait apparaître ses compétences
# sous le pli : il fallait faire défiler soi-même avant de pouvoir évaluer.
def ouvrir_premier_domaine(page)
  page.evaluate(%(document.querySelector(".mobile-domain-level").click()))
  sleep 1.0
  nb = page.evaluate(%(document.querySelectorAll(".mobile-skill-display:not(.d-none) .eval_bull").length))
  raise "aucune pastille visible après ouverture du premier domaine" if nb.zero?
end

def etape_recentrage(harness, page)
  puts "\n— Ouvrir un domaine amène ses compétences dans l'écran"
  page.evaluate("window.scrollTo(0, 0)")
  sleep 0.3

  dernier = ouvrir_dernier_domaine(page)
  etat = etat_du_domaine(page, dernier)

  harness.check("le panneau s'ouvre", etat["ouvert"])
  harness.check("le domaine n'est plus recouvert par l'en-tête " \
                "(#{etat['hautBloc'].round} ≥ #{etat['basEntete'].round})",
                etat["hautBloc"] >= etat["basEntete"] - 1)
  verifier_cible(harness, etat)
end

def verifier_cible(harness, etat)
  place = "#{etat['hautCible'].round}..#{etat['basCible'].round} sur #{etat['ecran'].round}"
  harness.check("la première compétence est visible (#{place})",
                etat["hautCible"] >= 0 && etat["basCible"] <= etat["ecran"])
  # Le pouce atteint le bas de l'écran, pas le haut : la cible ne doit pas se
  # coller sous l'en-tête, là où il faut changer de prise pour l'atteindre.
  harness.check("elle tombe dans la zone que le pouce atteint",
                etat["hautCible"] >= etat["ecran"] * 0.15)
end

# Le dernier domaine de la liste : c'est celui qui, ouvert, faisait apparaître
# ses compétences sous le pli.
def ouvrir_dernier_domaine(page)
  dernier = page.evaluate(%(document.querySelectorAll("[data-controller~='toggle-panel']").length)) - 1
  page.evaluate(<<~JS)
    document.querySelectorAll("[data-controller~='toggle-panel']")[#{dernier}]
            .querySelector(".mobile-domain-level").click()
  JS
  sleep 1.2
  dernier
end

def etat_du_domaine(page, rang)
  page.evaluate(<<~JS)
    (() => {
      const bloc = document.querySelectorAll("[data-controller~='toggle-panel']")[#{rang}];
      const panneau = bloc.querySelector(".mobile-skill-display");
      const entete = document.querySelector(".mobile-eval-header").getBoundingClientRect();
      const premiere = panneau.querySelector(".mobile-eval-display").getBoundingClientRect();
      return { ouvert: !panneau.classList.contains("d-none"),
               hautBloc: bloc.getBoundingClientRect().top,
               basEntete: entete.bottom,
               hautCible: premiere.top, basCible: premiere.bottom,
               ecran: window.innerHeight };
    })()
  JS
end

def domaine(nom, niveau, compteur)
  pastilles = %w[failed redo redo_OK].map do |statut|
    ApplicationController.render(partial: "shared/pastille_eval", locals: { statut:, lettre: "E" })
  end.join
  competences = (1..4).map do |i|
    <<~HTML
      <div class="mobile-skill-card">
        <div class="title-mobile-skill-card"><h3>&#9632;</h3><h6>#{nom} — compétence #{i}</h6></div>
        <div class="mobile-eval-display">
          <div class="previous_eval mt-2">#{pastilles}</div>
          <button type="button" class="bg-white">
            <div class="mobile-last-eval">
              #{ApplicationController.render(partial: 'shared/pastille_eval',
                                             locals: { statut: 'redo', lettre: 'E' })}
            </div>
          </button>
        </div>
      </div>
    HTML
  end.join
  <<~HTML
    <div data-controller="toggle-panel"
         data-toggle-panel-recentrer-value="true"
         data-toggle-panel-entete-value=".mobile-eval-header">
      <div class="domain">
        <div class="mobile-domain-level" data-action="click->toggle-panel#displayPanel">
          <div class="belt"><div class="d-flex justify-content-around">
            <div class="bd-maison"><i class="fas fa-bacon belt-#{niveau} mobile-belt font-weight-bold"></i></div>
          </div></div>
          <h3>#{nom}</h3>
          <i class="fa-solid fa-chevron-right --roseL mobile-domain-chevron" data-toggle-panel-target="btn"></i>
          <i class="fa-solid fa-chevron-down --roseL mobile-domain-chevron d-none" data-toggle-panel-target="btn"></i>
        </div>
      </div>
      <div class="mobile-skill-display d-none" id="domaine_#{compteur}" data-toggle-panel-target="panel">
        #{competences}
      </div>
    </div>
  HTML
end

# La feuille compilée désigne ses fontes par `/assets/…`, qu'une page `file://`
# ne sait pas joindre : sans elles, Font Awesome tombe en carrés vides, et un
# banc qui mesure une icône mesurerait alors la boîte du carré. On recopie les
# fichiers à côté de la page et on rend les chemins relatifs.
def emporter_les_fontes(harness)
  css = Rails.application.assets["application.css"].to_s
  FileUtils.mkdir_p(harness.dir.join("fontes"))
  css.scan(%r{url\((/assets/[^)]+\.(?:woff2?|ttf))\)}).flatten.uniq.each do |chemin|
    nom = recopier_la_fonte(harness, chemin)
    css = css.gsub("url(#{chemin})", "url(./fontes/#{nom})") if nom
  end
  File.write(harness.dir.join("application.css"), css)
end

# Le nom empreinté remonte au nom logique par le manifeste ; à défaut, en
# retirant l'empreinte.
def recopier_la_fonte(harness, chemin)
  empreinte = chemin.delete_prefix("/assets/")
  logique = Rails.application.assets_manifest.assets.key(empreinte) ||
            empreinte.sub(/-[0-9a-f]{64}(\.\w+)\z/, '\1')
  actif = Rails.application.assets[logique]
  return warn("fonte introuvable : #{logique}") unless actif

  File.basename(logique).tap { |nom| File.binwrite(harness.dir.join("fontes", nom), actif.to_s) }
end

harness = BrowserHarness::Runner.new("mobile_reperes_harness")
emporter_les_fontes(harness)
harness.dump_bundle

DOMAINES = [["Nombres et calculs", 3], ["Grandeurs et mesures", 5],
            ["Espace et géométrie", 2], ["Organisation de données", 6]].freeze

domaines = DOMAINES.each_with_index.map { |(nom, niveau), i| domaine(nom, niveau, i) }.join

harness.page("ecran",
             head: <<~HEAD,
               <title>banc repères mobile</title>
               <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
               <link rel="stylesheet" href="./application.css">
               <script src="./application.js" defer></script>
             HEAD
             body: <<~HTML)
               <div class="mobile_index">
                 <nav class="mobile-eval-header">
                   <a class="mobile-retour" href="#"><i class="fa-solid fa-chevron-left"></i><span>Plans de travail</span></a>
                   <div class="mobile-eval-header-details">
                     <div class="first-name"><h6 class="mobile-wp-dates">17/08/2026</h6><h4>Léo</h4></div>
                     <div class="title d-flex flex-column"><h3>Semaine 12</h3><p>Niveau : CM1</p></div>
                   </div>
                 </nav>
                 <p class="mobile-intro">Touchez une compétence pour enregistrer son évaluation.</p>
                 <div class="mobile-eval-wp">#{domaines}</div>
               </div>
               <nav class="navhaut"><div class="navbar-links">
                 <a href="#" class="top-link-no-bcg-btn">
                   <i class="fa-regular fa-comment icone-messages"><span class="bullet-chat"></span></i>
                 </a>
               </div></nav>
               <footer>
                 <div class="mobile-footer">
                   <div class="mobile-user-menu"><a href="#"><i class="fa-solid fa-school"></i></a></div>
                   <div class="mobile-user-menu"><a href="#"><i class="fa-solid fa-list"></i></a></div>
                   <div class="mobile-user-menu"><a href="#"><i class="fa-solid fa-graduation-cap"></i></a></div>
                   <div class="mobile-user-menu --actif"><a href="#">
                     <i class="fa-regular fa-comment icone-messages"><span class="bullet-chat"></span></i>
                   </a></div>
                   <div class="mobile-user-menu"><a href="#"><i class="fas fa-sign-out-alt"></i></a></div>
                 </div>
               </footer>
             HTML

harness.with_browser do |browser|
  page = browser.create_page
  page.resize(**IPHONE_12_MINI)
  page.go_to(harness.url("ecran"))
  sleep 0.8

  # Le même partiel sert dans la barre du bas, où l'icône fait 1,75rem, et dans
  # le nav du bureau, où elle en fait 1,5. Deux nombres en pixels ne pouvaient
  # convenir aux deux.
  etape_point_messages(harness, page, ".mobile-footer ")
  etape_point_messages(harness, page, ".top-link-no-bcg-btn ")

  # Les pastilles vivent dans les domaines : tant qu'ils sont fermés, il n'y a
  # rien à mesurer. Un banc qui ne s'en aperçoit pas rend « tout est vert » sur
  # un écran vide.
  ouvrir_premier_domaine(page)
  etape_anneau(harness, page)
  page.screenshot(path: harness.dir.join("pastilles.png").to_s, full: true)
  etape_recentrage(harness, page)
  page.screenshot(path: harness.dir.join("apres_ouverture.png").to_s, full: true)
  puts "\n  captures : #{harness.dir.join('pastilles.png')}"
  puts "             #{harness.dir.join('apres_ouverture.png')}"
end

harness.report!
