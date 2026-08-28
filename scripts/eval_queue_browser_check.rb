# frozen_string_literal: true

# Banc d'essai navigateur pour la file d'attente des évaluations.
#
#   bin/rails runner scripts/eval_queue_browser_check.rb
#
# Voir scripts/support/browser_harness.rb pour le pourquoi de ces bancs.
#
# Celui-ci a une propriété commode : la page est servie en `file://`, sans
# serveur, donc `fetch` échoue vraiment. Le scénario « hors connexion » n'est
# pas simulé, il est réel. Pour la suite, on remplace `fetch` par une fonction
# qui répond ce qu'on veut — succès, refus, session expirée — et on déclenche la
# reprise avec l'événement `online`, exactement comme le ferait un vrai retour
# de réseau.
require_relative "support/browser_harness"

URL_EVAL = "https://exemple.test/work_plan_skills/42/eval_update"
MARRON = "rgb(196, 64, 3)" # $marron, la couleur de la marque « en attente »

# La file passe par « Envoi… » avant de conclure : lire à heure fixe attrape
# parfois cet état transitoire. On attend donc l'état visé — une sonde qui
# dépend du temps qu'il fait ne garantit rien.
def attendre(secondes = 6)
  limite = Process.clock_gettime(Process::CLOCK_MONOTONIC) + secondes
  loop do
    return true if yield
    return false if Process.clock_gettime(Process::CLOCK_MONOTONIC) > limite

    sleep 0.05
  end
end

def bandeau(page)
  page.evaluate(<<~JS)
    (() => {
      const b = document.querySelector(".sync-status");
      return {
        visible: !b.hidden,
        etat: b.dataset.etat || "",
        texte: (b.querySelector(".sync-status-message").textContent || "").trim(),
        reessayer: !b.querySelector(".sync-status-retry").hidden,
      };
    })()
  JS
end

def attendre_etat(page, etat)
  attendre { bandeau(page)["etat"] == etat }
end

def file_stockee(page)
  page.evaluate(<<~JS)
    (() => {
      try {
        return JSON.parse(window.localStorage.getItem("ensemble.evaluations_en_attente.v1")) || [];
      } catch (e) { return null; }
    })()
  JS
end

def taper(page, bouton)
  page.execute(%{document.querySelector("##{bouton}").click()})
  attendre_etat(page, "hors_ligne")
end

def en_attente?(page)
  page.evaluate(%{document.querySelector(".mobile-eval-display").classList.contains("eval-en-attente")})
end

# La marque doit être réellement PEINTE, pas seulement décrite dans la feuille :
# un glyphe Font Awesome s'y résolvait en chaîne vide et ne montrait rien.
def couleur_marque(page)
  page.evaluate(<<~JS)
    getComputedStyle(document.querySelector(".eval-en-attente .mobile-last-eval"), "::after").backgroundColor
  JS
end

# Remplace `fetch` par une réponse choisie, puis déclenche la reprise.
def rejouer(page, corps_js)
  page.execute(<<~JS)
    window.fetch = #{corps_js};
    window.dispatchEvent(new Event("online"));
  JS
end

def reponse_js(succes:, status:, url:, redirected: false, corps: "")
  <<~JS
    () => Promise.resolve({ ok: #{succes}, redirected: #{redirected}, status: #{status},
                            url: "#{url}", text: () => Promise.resolve(#{corps.inspect}) })
  JS
end

def verifier_bandeau_hors_ligne(harness, page)
  b = bandeau(page)
  harness.check("le bandeau s'affiche", b["visible"])
  harness.check("il annonce le hors connexion", b["texte"].include?("Hors connexion"))
  harness.check("et s'accorde au singulier", b["texte"].include?("Elle sera envoyée"))
  harness.check("il ne promet pas de réessai manuel", b["reessayer"] == false)
end

def etape_hors_connexion(harness, page)
  puts "\n— Un appui alors que le réseau ne répond pas (page file://, fetch échoue)"
  taper(page, "reussi")

  pastille = page.evaluate(%{document.querySelector(".mobile-last-eval .eval_bull").className})
  harness.check("la pastille est peinte tout de suite", pastille.include?("completed"))
  harness.check("la compétence est marquée en attente", en_attente?(page))
  harness.check("la marque est peinte sur la pastille", couleur_marque(page) == MARRON)

  verifier_bandeau_hors_ligne(harness, page)
  verifier_geste_conserve(harness, page)
end

# Une capture pour l'œil : la sonde juge le comportement, pas la lisibilité.
def verifier_geste_conserve(harness, page)
  page.screenshot(path: harness.dir.join("hors_connexion.png").to_s, full: true)
  puts "  capture : #{harness.dir.join('hors_connexion.png')}"

  stockee = file_stockee(page)
  harness.check("le geste est écrit sur l'appareil", stockee.is_a?(Array) && stockee.size == 1)
  harness.check("avec le statut demandé", stockee&.first&.fetch("statut", nil) == "completed")
end

def etape_revirement(harness, page)
  puts "\n— L'enseignant se ravise avant le retour du réseau"
  taper(page, "a-refaire")

  stockee = file_stockee(page)
  harness.check("la file ne garde qu'un geste par compétence", stockee.is_a?(Array) && stockee.size == 1)
  harness.check("et c'est le dernier choix", stockee&.first&.fetch("statut", nil) == "redo")
end

def etape_session_expiree(harness, page)
  puts "\n— Session expirée : le serveur renvoie vers la page de connexion"
  rejouer(page, reponse_js(succes: true, status: 200, url: "https://exemple.test/users/sign_in", redirected: true))
  attendre_etat(page, "session")

  harness.check("le bandeau parle de session, pas de réseau",
                bandeau(page)["texte"].include?("session a expiré"))
  harness.check("le geste est conservé", file_stockee(page)&.size == 1)
end

def etape_refus(harness, page)
  puts "\n— Le serveur refuse (500)"
  rejouer(page, reponse_js(succes: false, status: 500, url: URL_EVAL))
  attendre_etat(page, "refus")

  b = bandeau(page)
  harness.check("le bandeau annonce un échec d'enregistrement",
                b["texte"].include?("n'a pas pu être enregistrée"))
  harness.check("et propose de réessayer", b["reessayer"])
end

def etape_retour_du_reseau(harness, page)
  puts "\n— Le réseau revient"
  html = '<div class="eval_bull redo"><i class="fa-solid fa-c"></i></div>'
  rejouer(page, reponse_js(succes: true, status: 200, url: URL_EVAL, corps: html))
  attendre_etat(page, "ok")

  verifier_confirmation(harness, page)
end

def verifier_confirmation(harness, page)
  harness.check("la file est vidée", file_stockee(page) == [])
  harness.check("le bandeau confirme", bandeau(page)["texte"].include?("Tout est enregistré"))
  harness.check("la marque d'attente disparaît", en_attente?(page) == false)
  harness.check("la réponse du serveur remplace la pastille",
                page.evaluate(%{document.querySelector(".mobile-last-eval").innerHTML}).include?("redo"))
  harness.check("puis le bandeau s'efface de lui-même",
                attendre(5) { bandeau(page)["visible"] == false })
end

harness = BrowserHarness::Runner.new("eval_queue_harness")
harness.dump_bundle
harness.dump_stylesheet("application")

harness.page("index",
             head: <<~HEAD,
               <title>banc file d'évaluations</title>
               <meta name="csrf-token" content="jeton-de-test">
               <link rel="stylesheet" href="./application.css">
             HEAD
             body: <<~HTML)
               <div class="sync-status" data-controller="sync-status" role="status" aria-live="polite" hidden>
                 <span class="sync-status-message" data-sync-status-target="message"></span>
                 <button type="button" class="sync-status-retry"
                         data-action="click->sync-status#reessayer"
                         data-sync-status-target="reessayer" hidden>Réessayer</button>
               </div>

               <div class="mobile-eval-display" data-controller="ajax-work-plan"
                    data-ajax-work-plan-id-value="42">
                 <div class="mobile-last-eval" data-ajax-work-plan-target="lastEval">
                   <div class="eval_bull new"><i class="fa-solid fa-c"></i></div>
                 </div>
                 <a id="reussi" href="#{URL_EVAL}?status=completed"
                    data-action="click->ajax-work-plan#toggle">réussi</a>
                 <a id="a-refaire" href="#{URL_EVAL}?status=redo"
                    data-action="click->ajax-work-plan#toggle">à refaire</a>
               </div>

               <script src="./application.js"></script>
             HTML

harness.with_browser do |browser|
  page = browser.create_page
  page.go_to(harness.url("index"))
  attendre { bandeau(page)["visible"] == false }

  puts "\n— Au repos"
  harness.check("le bandeau reste muet quand il n'y a rien à dire", bandeau(page)["visible"] == false)

  etape_hors_connexion(harness, page)
  etape_revirement(harness, page)
  etape_session_expiree(harness, page)
  etape_refus(harness, page)
  etape_retour_du_reseau(harness, page)
end

harness.report!
