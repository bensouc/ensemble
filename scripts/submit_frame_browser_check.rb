# frozen_string_literal: true

# Banc d'essai du contrôleur `submit-frame`.
#
#   bin/rails runner scripts/submit_frame_browser_check.rb
#
# Voir scripts/support/browser_harness.rb pour le pourquoi de ces bancs.
#
# Ce qui se vérifie ici tient en un point, mais c'est celui qui refermait la
# modale : le formulaire doit partir par `requestSubmit()`, que Turbo
# intercepte, et NON par `submit()`, qui contourne Turbo et recharge la page.
# Les deux se ressemblent à la lecture ; leur effet n'a rien à voir.
require_relative "support/browser_harness"

harness = BrowserHarness::Runner.new("submit_frame_harness")
harness.dump_bundle

harness.page("index",
             head: %(<title>banc submit-frame</title>),
             body: <<~HTML)
               <turbo-frame id="cadre">
                 <form id="formulaire" action="/quelque-part" method="get"
                       data-controller="submit-frame" data-action="change->submit-frame#submit">
                   <select id="ceinture" name="level">
                     <option value="1">Blanche</option>
                     <option value="3">Orange</option>
                   </select>
                 </form>
               </turbo-frame>

               <script src="./application.js"></script>
               <script>
                 // On enregistre laquelle des deux méthodes est appelée, sans
                 // laisser partir la requête.
                 window.appels = [];
                 HTMLFormElement.prototype.requestSubmit = function () { window.appels.push("requestSubmit"); };
                 HTMLFormElement.prototype.submit = function () { window.appels.push("submit"); };
               </script>
             HTML

harness.with_browser do |browser|
  page = browser.create_page
  page.go_to(harness.url("index"))
  sleep 0.6

  puts "\n— Changer la ceinture"
  page.execute(<<~JS)
    const select = document.querySelector("#ceinture");
    select.value = "3";
    select.dispatchEvent(new Event("change", { bubbles: true }));
  JS
  sleep 0.4

  appels = page.evaluate("window.appels")
  harness.check("le formulaire est bien envoyé (#{appels.inspect})", appels.any?)
  harness.check("par requestSubmit, que Turbo intercepte", appels.include?("requestSubmit"))
  # C'est `submit()` qui rechargeait la page et refermait la modale.
  harness.check("jamais par submit, qui contournerait Turbo", appels.exclude?("submit"))

  puts "\n— Le formulaire de l'index n'est pas visé"
  harness.check("aucun autre formulaire n'est touché",
                page.evaluate(%(document.querySelectorAll("form").length)) == 1)
end

harness.report!
