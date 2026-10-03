# frozen_string_literal: true

# Depuis Rails 7.2.3.2, Active Storage bloque lui-même, au démarrage, les
# formats d'image que libvips juge non fiables (GHSA-xr9x-r78c-5hrm, critique) :
# l'appel à `Vips.block_untrusted` que portait cet initializer en Rails 7.1 est
# parti avec la montée de version.
#
# Reste ce que Rails laisse à l'application : BMP, ICO et PSD n'ont que des
# loaders non fiables, une variante demandée pour eux lèverait donc
# `Vips::Error`, en pleine requête puisque les variantes se calculent à
# l'affichage. Active Storage les sert tels quels.
Rails.application.config.active_storage.variable_content_types -=
  %w[image/bmp image/vnd.microsoft.icon image/vnd.adobe.photoshop]
