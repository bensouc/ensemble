# frozen_string_literal: true

# Banc d'essai de l'action de Turbo Stream `ouvrir_dossier`.
#
#   bin/rails runner scripts/ouvrir_dossier_browser_check.rb
#
# Voir scripts/support/browser_harness.rb pour le pourquoi de ces bancs.
#
# Une action de stream maison échoue en silence : mal enregistrée, Turbo ignore
# la balise sans rien dire. On l'éprouve donc pour de vrai — on insère la balise
# dans la page et on regarde si le dossier s'est ouvert.
require_relative "support/browser_harness"

harness = BrowserHarness::Runner.new("ouvrir_dossier_harness")
harness.dump_bundle

harness.page("index",
             head: %(<title>banc ouvrir_dossier</title>),
             body: <<~HTML)
               <div class="challenges-by-skill" id="dossier_skill_42" data-controller="wp-by-student">
                 <i data-wp-by-student-target="folderopen"></i>
                 <i class="d-none" data-wp-by-student-target="folderclosed"></i>
                 <div data-wp-by-student-target="wplist" class="d-none">
                   <p>Les exercices de la compétence</p>
                 </div>
               </div>

               <div class="challenges-by-skill" id="dossier_skill_7" data-controller="wp-by-student">
                 <i data-wp-by-student-target="folderopen"></i>
                 <i class="d-none" data-wp-by-student-target="folderclosed"></i>
                 <div data-wp-by-student-target="wplist" class="d-none">
                   <p>Un autre dossier</p>
                 </div>
               </div>

               <script src="./application.js"></script>
             HTML

def ferme?(page, id)
  page.evaluate(
    %(document.querySelector("##{id} [data-wp-by-student-target='wplist']").classList.contains("d-none"))
  )
end

def jouer_action(page, cible)
  page.execute(<<~JS)
    const balise = document.createElement("turbo-stream");
    balise.setAttribute("action", "ouvrir_dossier");
    balise.setAttribute("cible", "#{cible}");
    balise.appendChild(document.createElement("template"));
    document.body.appendChild(balise);
  JS
  sleep 0.3
end

harness.with_browser do |browser|
  page = browser.create_page
  page.go_to(harness.url("index"))
  sleep 0.8

  puts "\n— Au départ"
  harness.check("les deux dossiers sont fermés", ferme?(page, "dossier_skill_42") && ferme?(page, "dossier_skill_7"))

  puts "\n— L'action ouvre le dossier visé"
  jouer_action(page, "dossier_skill_42")
  harness.check("le dossier visé s'ouvre", ferme?(page, "dossier_skill_42") == false)
  harness.check("les autres ne bougent pas", ferme?(page, "dossier_skill_7"))

  # `openList` n'ouvre que si c'est fermé : la rejouer ne doit pas refermer.
  puts "\n— Rejouée sur un dossier déjà ouvert"
  jouer_action(page, "dossier_skill_42")
  harness.check("le dossier reste ouvert", ferme?(page, "dossier_skill_42") == false)

  puts "\n— Sur un dossier absent de la page"
  erreurs = []
  page.on(:pageerror) { |e| erreurs << e.message }
  jouer_action(page, "dossier_skill_999")
  harness.check("aucune erreur : l'arrivée peut être hors écran", erreurs.empty?)
end

harness.report!
