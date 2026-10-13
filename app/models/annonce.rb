# frozen_string_literal: true

# Annonce affichée sur le tableau de bord, dans la même fenêtre que le guide
# « Bien commencer avec Ensemble ». On la ferme pour cette fois (« Plus tard »)
# ou pour de bon (« Ne plus afficher ») : ce second choix est retenu sur le
# compte (`users.annonces_masquees`).
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
    new(id: "nouvel-editeur-2026-10", titre: "Le tout nouvel éditeur d'exercice",
        partial: "annonces/nouvel_editeur")
  ].freeze

  # La plus récente que ce compte n'a pas écartée.
  def self.a_montrer(user)
    ACTIVES.find { |annonce| user.annonces_masquees.exclude?(annonce.id) }
  end

  def self.trouver(id)
    ACTIVES.find { |annonce| annonce.id == id }
  end
end
