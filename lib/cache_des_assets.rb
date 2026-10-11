# frozen_string_literal: true

# Les fichiers compilés de `/assets` portent l'empreinte de leur contenu dans
# leur nom (`application-4ef7f4f5.css`) : un fichier qui change change de nom.
# On peut donc les garder en cache un an, sans jamais les revalider. Sans cet
# en-tête, le navigateur retéléchargeait CSS et JS (425 Ko compressés) bien plus
# souvent que nécessaire, et à chaque visite après un déploiement.
#
# Seuls ces fichiers-là : `public_file_server.headers` aurait couvert tout
# `public/` — favicon, pages d'erreur, téléchargements —, dont le nom ne change
# pas quand le contenu change.
class CacheDesAssets
  EMPREINTE = %r{\A/assets/.+-[0-9a-f]{8,}\.[a-z0-9.]+\z}
  CACHE = "public, max-age=31536000, immutable"

  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)
    headers["cache-control"] = CACHE if status == 200 && env["PATH_INFO"].match?(EMPREINTE)
    [status, headers, body]
  end
end
