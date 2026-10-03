# frozen_string_literal: true

# Ferme GHSA-xr9x-r78c-5hrm (CVE-2026-66066), critique : en lisant une image
# piégée, l'un des « loaders » que libvips classe lui-même comme non fiables
# peut livrer le contenu de n'importe quel fichier du serveur, variables
# d'environnement comprises — donc `SECRET_KEY_BASE` et les clés Cloudinary,
# Stripe, SMTP. L'attaque n'exige qu'un envoi d'image, et n'importe qui peut
# ouvrir un compte de démonstration ; l'analyse faite à l'envoi suffit, nul
# besoin de demander une variante.
#
# Rails ne corrige qu'à partir de 7.2.3.2, en appelant au démarrage ce que fait
# cet initializer. Rails 7.1 n'aura pas ce correctif : à supprimer à la montée
# en 7.2, qui le fera d'elle-même.
require "nokogiri" # avant vips, qui charge aussi libxml2 (cf. Active Storage)
require "vips"

# Sous 8.13, libvips ne sait pas bloquer ces loaders : mieux vaut refuser de
# démarrer que tourner sans protection, comme le fait Rails.
unless Vips.at_least_libvips?(8, 13)
  raise "libvips #{Vips.version_string} ne sait pas bloquer les formats non fiables : il faut 8.13 ou plus"
end

Vips.block_untrusted(true)

# BMP, ICO et PSD n'ont que des loaders non fiables : une variante demandée pour
# eux lèverait désormais `Vips::Error`, en pleine requête puisque les variantes
# se calculent à l'affichage. Active Storage les sert donc tels quels.
Rails.application.config.active_storage.variable_content_types -=
  %w[image/bmp image/vnd.microsoft.icon image/vnd.adobe.photoshop]
