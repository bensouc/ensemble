# Be sure to restart your server when you modify this file.

# Propshaft sert et versionne les fichiers des chemins d'assets : les images, les
# polices, et ce que esbuild et Dart Sass construisent dans app/assets/builds.

# Version of your assets, change this if you want to expire all your assets.
# Le service worker la reprend dans le nom de son cache.
Rails.application.config.assets.version = "1.0"

# Les sources Sass ne sont pas servies : seule leur version construite l'est
# (app/assets/builds, par bin/build-css).
Rails.application.config.assets.excluded_paths << Rails.root.join("app/assets/stylesheets")
# Ni les sources JS : esbuild les rassemble dans app/assets/builds. importmap-rails
# (tiré par Mission Control) les ajoute aux chemins APRÈS que Propshaft a appliqué
# `excluded_paths` : on les retire donc une fois l'application démarrée.
Rails.application.config.after_initialize do |app|
  sources_js = %w[app/javascript vendor/javascript].map { |dossier| Rails.root.join(dossier).to_s }
  app.config.assets.paths.reject! { |chemin| sources_js.include?(chemin.to_s) }
end

# Les assets de la gem rails_admin servent son mode Sprockets (gabarits .erb
# compris) : en mode `:webpack`, son CSS et son JS viennent de son paquet npm,
# construits avec ceux de l'app.
Rails.application.config.assets.excluded_paths.concat(Dir[RailsAdmin::Engine.root.join("{app,vendor}/assets/*").to_s])

# Les polices de Font Awesome, à la racine des assets : les feuilles construites
# les désignent par `url("./fa-solid-900.woff2")`, que Propshaft réécrit vers
# le fichier versionné.
Rails.application.config.assets.paths << Rails.root.join("node_modules/@fortawesome/fontawesome-free/webfonts")
