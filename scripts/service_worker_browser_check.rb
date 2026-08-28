# frozen_string_literal: true

# Banc d'essai pour les décisions du service worker.
#
#   bin/rails runner scripts/service_worker_browser_check.rb
#
# Un service worker ne s'enregistre que sur un contexte sécurisé : impossible à
# éprouver depuis une page `file://`. Ses fonctions de DÉCISION, elles, sont
# pures et sans dépendance au contexte — on charge donc le vrai fichier rendu
# comme un script ordinaire et on les interroge directement. Les écouteurs
# `install`/`fetch` qu'il installe au passage restent inertes sur une page.
#
# Ce qui est vérifié ici, c'est ce qui a des conséquences : ne jamais mettre en
# cache une écriture, effacer les données d'élèves à la déconnexion, et dire à
# l'enseignant quand il lit une page périmée.
require_relative "support/browser_harness"

harness = BrowserHarness::Runner.new("service_worker_harness")

# Le vrai fichier, rendu par Rails, empreintes d'assets comprises.
File.write(harness.dir.join("service-worker.js"),
           ApplicationController.render(template: "pwa/service_worker", formats: :js, layout: false))

harness.page("index",
             head: %(<title>banc service worker</title>),
             body: %(<script src="./service-worker.js"></script>))

def strategie(page, chemin, methode: "GET", mode: "navigate")
  page.evaluate(
    %{strategiePour({ url: "https://ensemble.test#{chemin}", method: "#{methode}", mode: "#{mode}" })}
  )
end

CAS = [
  ["une page mobile se garde pour le hors réseau", "/mobile/work_plans", {}, "donnees"],
  ["une fiche élève aussi", "/mobile/classrooms/1/students/2", {}, "donnees"],
  ["le bundle et la feuille se gardent à part", "/assets/application-abc.js", { mode: "no-cors" }, "coque"],
  ["une écriture ne se met JAMAIS en cache", "/work_plan_skills/42/eval_update",
   { methode: "PATCH", mode: "cors" }, "passe"],
  ["la déconnexion efface les données d'élèves", "/users/sign_out", {}, "purge"],
  ["un PDF ne se met pas en cache", "/work_plans/7/export", {}, "passe"],
  ["le bureau n'est pas mis en cache", "/work_plans", {}, "passe"],
  ["une requête non-GET passe outre", "/mobile/work_plans", { methode: "POST" }, "passe"]
].freeze

harness.with_browser do |browser|
  page = browser.create_page
  page.go_to(harness.url("index"))
  sleep 0.4

  puts "\n— Ce que le service worker décide de faire"
  CAS.each do |libelle, chemin, options, attendu|
    harness.check(libelle, strategie(page, chemin, **options) == attendu)
  end

  puts "\n— L'estampille des pages servies depuis le cache"
  estampille = page.evaluate(
    %{estampiller("<html><head><title>x</title></head><body>y</body></html>", "2026-08-28T14:12:00Z")}
  )
  harness.check("la page dit d'où elle vient", estampille.include?('name="servi-depuis-cache"'))
  harness.check("avec la date de mise en cache", estampille.include?("2026-08-28T14:12:00Z"))
  harness.check("posée dans l'en-tête du document", estampille.include?("</head>"))
  harness.check("sans abîmer le corps de la page", estampille.include?("<body>y</body>"))

  sans_tete = page.evaluate(%{estampiller("<p>fragment</p>", "2026-08-28T14:12:00Z")})
  harness.check("un fragment sans <head> reste estampillé", sans_tete.include?("servi-depuis-cache"))
end

harness.report!
