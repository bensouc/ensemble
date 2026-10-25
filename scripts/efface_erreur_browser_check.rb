# frozen_string_literal: true

# Banc d'essai du contrôleur `efface-erreur`.
#
#   bin/rails runner scripts/efface_erreur_browser_check.rb
#
# Voir scripts/support/browser_harness.rb pour le pourquoi de ces bancs.
#
# L'erreur qu'a rendue le serveur doit partir dès qu'on retape dans CE champ, et
# seulement dans lui. Le balisage est celui du wrapper `vertical_form` de
# simple_form.
require_relative "support/browser_harness"

harness = BrowserHarness::Runner.new("efface_erreur_harness")
harness.dump_bundle

harness.page("index",
             head: %(<title>banc efface-erreur</title>),
             body: <<~HTML)
               <form id="formulaire" data-controller="efface-erreur" data-action="input->efface-erreur#effacer">
                 <div class="form-group form-group-invalid" id="groupe-prenom">
                   <label for="user_first_name">Prénom</label>
                   <input class="form-control is-invalid" id="user_first_name" name="user[first_name]" value="">
                   <div class="invalid-feedback">Prénom doit être rempli(e)</div>
                 </div>
                 <div class="form-group form-group-invalid" id="groupe-nom">
                   <label for="user_last_name">Nom</label>
                   <input class="form-control is-invalid" id="user_last_name" name="user[last_name]" value="">
                   <div class="invalid-feedback">Nom doit être rempli(e)</div>
                 </div>
               </form>

               <script src="./application.js"></script>
             HTML

def taper(page, selecteur, texte)
  page.execute(<<~JS)
    const champ = document.querySelector(#{selecteur.to_json});
    champ.value = #{texte.to_json};
    champ.dispatchEvent(new Event("input", { bubbles: true }));
  JS
  sleep 0.2
end

harness.with_browser do |browser|
  page = browser.create_page
  page.go_to(harness.url("index"))
  sleep 0.6

  puts "\n— Retaper dans le prénom en erreur"
  taper(page, "#user_first_name", "B")
  harness.check("le champ n'est plus marqué en erreur",
                !page.evaluate(%(document.querySelector("#user_first_name").classList.contains("is-invalid"))))
  harness.check("son message est parti",
                page.evaluate(%(document.querySelector("#groupe-prenom .invalid-feedback"))).nil?)
  harness.check("son groupe non plus n'est plus en erreur",
                !page.evaluate(%(document.querySelector("#groupe-prenom").classList.contains("form-group-invalid"))))

  puts "\n— L'autre champ ne bouge pas"
  harness.check("l'erreur du nom reste, tant qu'on n'y a pas touché",
                page.evaluate(%(document.querySelector("#user_last_name").classList.contains("is-invalid"))) &&
                page.evaluate(%(document.querySelector("#groupe-nom .invalid-feedback")?.textContent)) ==
                  "Nom doit être rempli(e)")
end

harness.report!
