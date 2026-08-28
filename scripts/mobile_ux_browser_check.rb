# frozen_string_literal: true

# Banc d'essai des propriétés d'ergonomie du front mobile.
#
#   bin/rails runner scripts/mobile_ux_browser_check.rb
#
# Voir scripts/support/browser_harness.rb pour le pourquoi de ces bancs.
#
# Ce qui est vérifié ici n'est pas affaire de goût mais de fait : le texte ne
# doit pas dépendre de la hauteur de la fenêtre, le doigt doit atteindre ses
# cibles, la page ne doit pas déborder, l'en-tête ne doit rien recouvrir, et la
# modale d'évaluation doit se lire au lieu de se deviner. Un coup d'œil ne
# tranche aucune de ces questions.
require_relative "support/browser_harness"

CARTE_MINIMALE = 100 # px : en deçà, « OK, mais à refaire » se hache
GRIS_FONCE = "rgb(61, 61, 61)" # $grisF
ROSE = "rgb(242, 65, 80)" # $rose

def mesure(page, selecteur, propriete)
  page.evaluate(%(getComputedStyle(document.querySelector("#{selecteur}")).#{propriete}))
end

def boite(page, selecteur)
  page.evaluate(<<~JS)
    (() => {
      const r = document.querySelector("#{selecteur}").getBoundingClientRect();
      return { largeur: r.width, hauteur: r.height, haut: r.top, gauche: r.left };
    })()
  JS
end

def debordement?(page)
  page.evaluate(%(document.documentElement.scrollWidth > document.documentElement.clientWidth))
end

def largeurs(page, selecteur)
  page.evaluate(<<~JS)
    Array.from(document.querySelectorAll("#{selecteur}")).map((e) => Math.round(e.getBoundingClientRect().width))
  JS
end

# Deux téléphones de hauteurs très différentes : un texte dimensionné en `vh`
# change entre les deux, un texte en rem ne bouge pas.
def tailles_de_texte(page, largeur, hauteur)
  page.resize(width: largeur, height: hauteur)
  sleep 0.2
  %w[.title .mobile-classe-nom .mobile-eleve-compte].index_with { |s| mesure(page, s, "fontSize") }
end

def etape_typographie(harness, page)
  puts "\n— Le texte ne dépend plus de la hauteur de l'écran"
  petit = tailles_de_texte(page, 375, 667) # iPhone SE
  grand = tailles_de_texte(page, 375, 932) # iPhone 15 Pro Max
  harness.check("mêmes tailles sur un petit et un grand téléphone", petit == grand)
  puts "  (#{petit.map { |s, v| "#{s} #{v}" }.join(', ')})"

  paysage = tailles_de_texte(page, 667, 375)
  harness.check("le texte ne s'effondre pas en paysage", paysage[".title"] == petit[".title"])
end

def etape_cibles_tactiles(harness, page)
  puts "\n— Le doigt atteint ses cibles (seuil 44px)"
  page.resize(width: 390, height: 844)
  sleep 0.2

  { ".mobile-last-eval" => "la pastille d'évaluation",
    ".mobile-eval-display button" => "le bouton qui ouvre l'évaluation",
    ".mobile-user-menu a" => "chaque entrée de la barre du bas",
    ".mobile-eval-choix" => "chaque statut dans la modale" }.each do |selecteur, libelle|
    b = boite(page, selecteur)
    harness.check("#{libelle} (#{b['largeur'].round}×#{b['hauteur'].round})",
                  b["largeur"] >= 44 && b["hauteur"] >= 44)
  end

  verifier_gouttiere(harness, page)
end

def verifier_gouttiere(harness, page)
  gouttiere = boite(page, ".previous_eval")
  harness.check("la gouttière des évaluations passées reste étroite (#{gouttiere['largeur'].round}px)",
                gouttiere["largeur"] <= 110)
end

def etape_largeur_ecran(harness, page)
  puts "\n— La page se tient dans l'écran"
  [320, 375, 390, 430, 768].each do |largeur|
    page.resize(width: largeur, height: 844)
    sleep 0.15
    harness.check("aucun débordement latéral à #{largeur}px", debordement?(page) == false)
  end
end

# Titres et texte flottaient au centre, sans axe commun avec les cartes qui les
# suivaient.
def etape_alignement(harness, page)
  puts "\n— Tout s'aligne sur le même axe"
  page.resize(width: 390, height: 844)
  sleep 0.2

  harness.check("le corps de l'écran est aligné à gauche",
                mesure(page, ".mobile_index", "textAlign") == "left")
  verifier_bord_commun(harness, page)
end

def verifier_bord_commun(harness, page)
  gauches = %w[.title .mobile-intro .mobile-classe-carte].map do |selecteur|
    boite(page, selecteur)["gauche"].round
  end
  harness.check("titre, texte et cartes partagent le même bord gauche (#{gauches.inspect})",
                gauches.uniq.size == 1)

  # Les plans d'un élève sont en retrait sous son prénom : c'est voulu, la marge
  # dit à qui ils appartiennent.
  plan = boite(page, ".mobile-index-wp-card")["gauche"]
  harness.check("les plans restent en retrait sous leur élève",
                plan > gauches.first)
end

def etape_entete(harness, page)
  puts "\n— L'en-tête ne recouvre plus les compétences"
  page.resize(width: 390, height: 844)
  sleep 0.2

  harness.check("il se réserve sa place au lieu d'être fixe",
                mesure(page, ".mobile-eval-header", "position") == "sticky")
  entete = boite(page, ".mobile-eval-header")
  contenu = boite(page, ".mobile-eval-wp")
  harness.check("le contenu commence sous lui",
                contenu["haut"] >= entete["haut"] + entete["hauteur"] - 1)
end

def etape_modale(harness, page)
  puts "\n— La modale d'évaluation se lit au lieu de se deviner"
  page.resize(width: 390, height: 844)
  sleep 0.2

  verifier_libelles(harness, page)

  harness.check("les statuts forment une grille", mesure(page, ".mobile-eval-mngt", "display") == "grid")
  harness.check("chaque statut est une carte, icône au-dessus du mot",
                mesure(page, ".mobile-eval-choix", "flexDirection") == "column")
  harness.check("le libellé n'est pas noyé dans le bleu des liens",
                mesure(page, ".mobile-eval-choix", "color") == GRIS_FONCE)

  verifier_cartes(harness, page)
end

def verifier_libelles(harness, page)
  libelles = page.evaluate(<<~JS)
    Array.from(document.querySelectorAll(".mobile-eval-libelle")).map((e) => e.textContent.trim())
  JS
  harness.check("chaque statut porte son libellé", libelles.all? { |l| l.length > 2 })
  harness.check("les mots du bureau y sont", libelles.include?("À refaire"))
  # Trois flèches de rotation ne se distinguaient que par leur couleur : c'est
  # le mot qui lève l'ambiguïté, pas la teinte.
  harness.check("les libellés sont tous différents", libelles.uniq.size == libelles.size)
end

def verifier_cartes(harness, page)
  cartes = largeurs(page, ".mobile-eval-choix")
  harness.check("les cartes sont assez larges (#{cartes.inspect})", cartes.all? { |l| l >= CARTE_MINIMALE })
  # Un nombre impair laissait une carte seule, calée à gauche.
  harness.check("aucune carte orpheline : l'impaire prend toute la largeur",
                cartes.size.odd? ? cartes.last > cartes.first * 1.5 : cartes.uniq.size == 1)
  verifier_lisibilite(harness, page)
  verifier_statut_courant(harness, page)
end

# Le libellé est ce qui distingue trois flèches identiques : il ne peut pas être
# le plus discret de la carte.
def verifier_lisibilite(harness, page)
  harness.check("le libellé est lisible, pas discret",
                mesure(page, ".mobile-eval-libelle", "fontSize") == "14px" &&
                mesure(page, ".mobile-eval-libelle", "fontWeight") == "600")
end

# Le statut en cours se signale par sa bordure et son fond, pas par une nuance
# de gras qu'on ne remarque pas.
def verifier_statut_courant(harness, page)
  harness.check("le statut actuel se voit au premier coup d'œil",
                mesure(page, ".mobile-eval-choix.--courant", "borderColor") == ROSE &&
                mesure(page, ".mobile-eval-choix.--courant", "borderWidth") == "2px")
  harness.check("les autres cartes ne le sont pas",
                mesure(page, ".mobile-eval-choix:not(.--courant)", "borderWidth") == "1px")
end

def etape_carte_classe(harness, page)
  puts "\n— La classe ouverte contient ses élèves"
  page.resize(width: 390, height: 844)
  sleep 0.2

  verifier_contenance(harness, page)
  verifier_alignement_chevrons(harness, page)
  verifier_ecran_plans(harness, page)
  verifier_barre_du_bas(harness, page)
end

# Les cinq icônes de la barre étaient de la même couleur : rien ne disait où
# l'on se trouvait.
def verifier_barre_du_bas(harness, page)
  harness.check("l'onglet courant s'allume",
                mesure(page, ".mobile-user-menu.--actif a", "color") == ROSE)
  harness.check("les autres restent en retrait",
                mesure(page, ".mobile-user-menu:not(.--actif) a", "color") != ROSE)
  # La couleur seule ne suffit pas à qui la distingue mal.
  harness.check("un trait double la couleur",
                mesure(page, ".mobile-user-menu.--actif", "position") == "relative")
end

def verifier_contenance(harness, page)
  carte = boite(page, ".mobile-classe-carte")
  eleve = boite(page, ".mobile-eleve-ligne")
  harness.check("les élèves sont DANS la carte, pas dessous",
                eleve["haut"] > carte["haut"] &&
                eleve["haut"] + eleve["hauteur"] <= carte["haut"] + carte["hauteur"] + 1)
  # Les classes se touchaient : rien ne séparait une carte de sa voisine.
  harness.check("les classes sont séparées les unes des autres",
                mesure(page, ".mobile-classe-carte", "marginBottom") == "8px")
  verifier_lignes_atteignables(harness, page, eleve)
end

def verifier_lignes_atteignables(harness, page, eleve)
  harness.check("chaque élève est une ligne atteignable (#{eleve['hauteur'].round}px)",
                eleve["hauteur"] >= 44)
  harness.check("l'en-tête de la classe aussi",
                boite(page, ".mobile-classe-entete")["hauteur"] >= 44)
end

# L'écran des plans de travail reprenait un dessin à lui : dossiers en guise de
# chevrons, compte entre parenthèses italiques, titre de classe en h1 nu.
def verifier_ecran_plans(harness, page)
  harness.check("l'écran des plans reprend la carte des classes",
                mesure(page, ".mobile-classe-entete.--titre", "backgroundColor") == "rgb(255, 227, 207)")

  # « À droite du prénom » se mesure horizontalement : les hauteurs diffèrent de
  # quelques pixels à cause du fond de la pastille, ce qui ne dit rien du rang.
  compte = boite(page, ".mobile-eleve-compte")
  prenom = boite(page, ".mobile-eleve-prenom")
  harness.check("le compte de plans se range à droite du prénom",
                compte["gauche"] > prenom["gauche"] + prenom["largeur"])

  # La carte d'un plan se lit en deux temps : le nom, puis la période.
  harness.check("le plan de travail est une carte en colonne",
                mesure(page, ".mobile-index-wp-card", "flexDirection") == "column")
  harness.check("le rose se réduit à un liseré au lieu d'un aplat",
                mesure(page, ".mobile-index-wp-card", "backgroundColor") == "rgb(255, 255, 255)" &&
                mesure(page, ".mobile-index-wp-card", "borderLeftColor") == ROSE)
end

# Un élève déplié gardait son chevron collé au prénom, au lieu de le laisser à
# droite comme ses voisins : la colonne des flèches se brisait.
def verifier_alignement_chevrons(harness, page)
  droites = page.evaluate(<<~JS)
    Array.from(document.querySelectorAll(".mobile-eleve-ligne i"))
         .map((e) => Math.round(e.getBoundingClientRect().right))
  JS
  harness.check("le chevron reste au même endroit, ouvert comme fermé (#{droites.inspect})",
                droites.uniq.size == 1)
end

harness = BrowserHarness::Runner.new("mobile_ux_harness")
harness.dump_stylesheet("application")

harness.page("index",
             head: %(<title>banc ergonomie mobile</title><link rel="stylesheet" href="./application.css">),
             body: <<~HTML)
               <div class="mobile_index">
                 <h1 class="title">Mes classes</h1>
                 <p class="mobile-intro">Ouvrez une classe pour consulter les ceintures de vos élèves.</p>
                 <div class="greyline-mobile"></div>
                 <div class="mobile-classe-carte --ouverte">
                   <a href="#" class="mobile-classe-entete">
                     <span class="mobile-classe-niveau">CM1</span>
                     <span class="mobile-classe-corps">
                       <span class="mobile-classe-nom">CM1 A</span>
                       <span class="mobile-classe-effectif">3 élèves</span>
                     </span>
                     <i class="fa-solid fa-chevron-down --roseL"></i>
                   </a>
                   <div class="mobile-classe-eleves">
                     <a href="#" class="mobile-eleve-ligne">
                       <span class="mobile-eleve-prenom">Léo</span>
                       <i class="fa-solid fa-chevron-right --roseL"></i>
                     </a>
                     <a href="#" class="mobile-eleve-ligne">
                       <span class="mobile-eleve-prenom">Mia</span>
                       <i class="fa-solid fa-chevron-right --roseL"></i>
                     </a>
                     <a href="#" class="mobile-eleve-ligne --ouverte">
                       <span class="mobile-eleve-prenom">Sara</span>
                       <i class="fa-solid fa-chevron-up --roseL"></i>
                     </a>
                   </div>
                 </div>

                 <div class="mobile-classe-carte">
                   <div class="mobile-classe-entete --titre">
                     <span class="mobile-classe-niveau">CE2</span>
                     <span class="mobile-classe-corps">
                       <span class="mobile-classe-nom">CE2 A</span>
                       <span class="mobile-classe-effectif">3 élèves</span>
                     </span>
                   </div>
                   <div class="mobile-classe-eleves">
                     <div class="mobile-eleve-ligne">
                       <span class="mobile-eleve-prenom">Abel</span>
                       <span class="mobile-eleve-compte">1 plan</span>
                       <i class="fa-solid fa-chevron-right --roseL"></i>
                     </div>
                     <div class="mobile-eleve-plans">
                       <a href="#" class="mobile-index-wp-card">
                         <span class="mobile-namept">Semaine 12</span>
                         <span class="mobile-wp-dates">17/08/2026 au 21/08/2026</span>
                       </a>
                     </div>
                   </div>
                 </div>

                 <nav class="mobile-eval-header">
                   <div class="mobile-eval-header-details">
                     <div class="first-name"><h4>Léo</h4></div>
                     <div class="title"><h3>Semaine 12</h3></div>
                   </div>
                 </nav>

                 <div class="mobile-eval-wp">
                   <div class="mobile-skill-card">
                     <div class="title-mobile-skill-card"><h3>◼</h3><h6>Accorder le verbe</h6></div>
                     <div class="mobile-eval-display">
                       <div class="previous_eval"><div class="eval_bull new"></div></div>
                       <button type="button">
                         <div class="mobile-last-eval"><div class="eval_bull completed"></div></div>
                       </button>
                     </div>
                   </div>
                   <div class="mobile-eval-mngt">
                     <a href="#" class="mobile-eval-choix">
                       <i class="fa-regular fa-circle-xmark --grisF eval-icon"></i>
                       <span class="mobile-eval-libelle">Non fait</span>
                     </a>
                     <a href="#" class="mobile-eval-choix --courant">
                       <i class="fa-solid fa-arrow-rotate-left orange eval-icon"></i>
                       <span class="mobile-eval-libelle">À refaire</span>
                     </a>
                     <a href="#" class="mobile-eval-choix">
                       <i class="fa-solid fa-graduation-cap text-primary eval-icon"></i>
                       <span class="mobile-eval-libelle">Validé ⇒ ceinture</span>
                     </a>
                   </div>
                 </div>
               </div>

               <footer>
                 <div class="mobile-footer">
                   <div class="mobile-user-menu --actif"><a href="#" aria-current="page">A</a></div>
                   <div class="mobile-user-menu"><a href="#">B</a></div>
                 </div>
               </footer>
             HTML

harness.with_browser do |browser|
  page = browser.create_page
  page.go_to(harness.url("index"))
  sleep 0.4

  etape_typographie(harness, page)
  etape_cibles_tactiles(harness, page)
  etape_largeur_ecran(harness, page)
  etape_alignement(harness, page)
  etape_entete(harness, page)
  etape_modale(harness, page)
  etape_carte_classe(harness, page)

  page.resize(width: 390, height: 844)
  sleep 0.2
  page.screenshot(path: harness.dir.join("mobile.png").to_s, full: true)
  puts "\n  capture : #{harness.dir.join('mobile.png')}"
end

harness.report!
