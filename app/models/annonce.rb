# frozen_string_literal: true

# Annonce affichée sur le tableau de bord, dans la même fenêtre que le guide
# « Bien commencer avec Ensemble ». « Plus tard » la remet au lendemain
# (`users.annonces_reportees`), « Ne plus afficher » l'écarte pour de bon
# (`users.annonces_masquees`) : deux choix retenus sur le compte.
#
# Pour en publier une nouvelle : l'ajouter en tête de ACTIVES, avec son partial
# dans app/views/annonces/. Un identifiant ne se réutilise jamais : c'est lui
# qui dit qui l'a déjà écartée.
class Annonce
  attr_reader :id, :titre, :partial

  def initialize(id:, titre:, partial:)
    @id = id
    @titre = titre
    @partial = partial
  end

  ACTIVES = [
    new(id: "validation-mobile-2026-10", titre: "Valider des compétences depuis votre téléphone",
        partial: "annonces/validation_mobile"),
    new(id: "nouvel-editeur-2026-10", titre: "Le tout nouvel éditeur d'exercice",
        partial: "annonces/nouvel_editeur")
  ].freeze

  # La plus récente que ce compte n'a ni écartée, ni remise à plus tard aujourd'hui.
  def self.a_montrer(user, aujourd_hui: Date.current)
    ACTIVES.find do |annonce|
      user.annonces_masquees.exclude?(annonce.id) && user.annonces_reportees[annonce.id] != aujourd_hui.iso8601
    end
  end

  def self.trouver(id)
    ACTIVES.find { |annonce| annonce.id == id }
  end
end
