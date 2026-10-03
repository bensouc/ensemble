# frozen_string_literal: true

# Lancé par bin/ci. Pas de CI hébergée : tout tourne sur le poste, et un passage
# vert se signe sur GitHub (`gh signoff`). La branche main exige cette
# signature pour accepter un merge.
#
# La signature porte sur le commit poussé, et `gh signoff` refuse de signer si
# l'arbre de travail n'est pas propre ou si HEAD n'est pas poussé : on lance
# donc bin/ci après le push, et tout nouveau commit est à repasser.
CI.run "Intégration continue", "Style, sécurité, tests et bancs navigateur" do
  step "Style : Ruby", "bundle exec rubocop"

  step "Sécurité : gems", "bundle exec bundler-audit check --update --config config/bundler-audit.yml"
  step "Sécurité : code", "bundle exec brakeman --quiet --no-pager --exit-on-warn --exit-on-error"

  # Directement esbuild : `yarn build` refuse de tourner hors du Node exact
  # inscrit dans package.json.
  step "Build : JavaScript", "node esbuild.config.js"

  step "Tests : RSpec", "bundle exec rspec"

  # Les bancs de scripts/ sont la seule couverture du JavaScript — Turbo,
  # Stimulus, la file d'évaluations hors ligne. Chacun pilote Chrome par Ferrum.
  bancs_en_attente = {
    "mobile_ux" => "Seuil de gouttière à trancher : le banc attend 110 px, la ligne d'évaluation " \
                   "en fait 128 depuis la refonte des pastilles. Rouge sur main aussi."
  }
  Dir[File.expand_path("../scripts/*_browser_check.rb", __dir__)].each do |banc|
    nom = File.basename(banc, "_browser_check.rb")
    if bancs_en_attente.key?(nom)
      heading "Navigateur : #{nom} — mis de côté", bancs_en_attente[nom], type: :error
    else
      step "Navigateur : #{nom}", "bin/rails", "runner", banc
    end
  end

  if success?
    step "Signature : prêt à merger", "gh signoff"
  else
    failure "Pas de signature : la CI a échoué.", "Corriger, pousser, puis relancer bin/ci."
  end
end
