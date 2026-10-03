# frozen_string_literal: true

# En développement, Active Storage écrit dans le MÊME compte Cloudinary que la
# production (`bensoucdev`), et la base de dev est une copie de la prod. Toute
# suppression d'une pièce jointe venue de la prod effaçait donc le vrai fichier
# de production : remplacer un avatar, supprimer un exercice ou une photo.
# C'est arrivé le 03/10/2026 à l'avatar de Benoît (blob 1159, créé en 2024).
#
# Ici, les suppressions sont ignorées et tracées dans le journal. Les envois
# partent toujours sur le compte partagé : un fichier en trop ne casse rien.
if Rails.env.development?
  module CloudinarySansSuppressionEnDev
    def delete(key)
      Rails.logger.warn("[cloudinary] suppression ignorée en dev, compte partagé avec la prod : #{key}")
    end

    def delete_prefixed(prefix)
      Rails.logger.warn("[cloudinary] suppression ignorée en dev, compte partagé avec la prod : #{prefix}*")
    end
  end

  # Le service de la gem lit ActiveStorage::Blob dès son chargement : on attend
  # que le modèle existe.
  ActiveSupport.on_load(:active_storage_blob) do
    require "active_storage/service/cloudinary_service"
    ActiveStorage::Service::CloudinaryService.prepend(CloudinarySansSuppressionEnDev)
  end
end
