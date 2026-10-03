# frozen_string_literal: true

# Les tailles auxquelles les textes affichent leurs images, en un seul endroit :
# la vue (active_storage/blobs/_blob) les demande, PrechauffageVariantes les
# fabrique d'avance. Si les deux divergeaient, la tâche fabriquerait des
# variantes que personne n'affiche, et chaque image serait recalculée au premier
# affichage malgré tout.
module VariantesImages
  TEXTE = { resize_to_limit: [1024, 768] }.freeze
  GALERIE = { resize_to_limit: [800, 600] }.freeze

  def self.representation(blob, galerie: false)
    blob.representation(galerie ? GALERIE : TEXTE)
  end
end
