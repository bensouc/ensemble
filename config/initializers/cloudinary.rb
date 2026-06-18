# Force les URLs générées par Cloudinary à utiliser HTTPS.
#
# Sans ça, Cloudinary génère des URLs en http:// → sur une page servie en HTTPS,
# le navigateur affiche un avertissement "Mixed Content" (et upgrade l'image au
# coup par coup). Avec secure = true, les URLs sont directement en https://.
#
# Le reste de la config (cloud_name / api_key / api_secret) provient de la
# variable d'environnement CLOUDINARY_URL.
Cloudinary.config do |config|
  config.secure = true
end
