# frozen_string_literal: true

# Les gabarits de Manipule, qui ne partagent rien avec le reste d'Ensemble.
module ManipuleHelper
  # L'adresse d'un morceau d'audio, portant l'empreinte de sa dernière
  # fabrication.
  #
  # L'identifiant d'un morceau ne bouge pas quand son contenu change : corriger
  # un énoncé, ou changer de voix, réécrit la même ligne. Or le contrôleur
  # annonce une semaine de cache — sans empreinte dans l'adresse, le navigateur
  # d'un élève continuerait à jouer l'ancienne lecture jusqu'à huit jours après
  # la correction, et l'enseignante n'aurait aucun moyen de s'en apercevoir.
  #
  # Avec l'empreinte, l'adresse change à chaque refabrication et la semaine de
  # cache reste acquise à tout ce qui n'a pas bougé.
  # Les écrans de l'enseignante, dans l'ordre où elle les parcourt : elle
  # écrit des manipulations, puis elle désigne qui les travaille. « Les résultats »
  # viendra en quatrième quand il aura sa page à lui ; pour l'instant le suivi
  # d'une classe les porte.
  def onglets_manipule
    onglets = [
      { libelle: "Accueil", chemin: manipule_root_path, controleurs: %w[accueil] },
      { libelle: "Les manipulations", chemin: manipule_banque_path, controleurs: %w[banque] },
      { libelle: "Mes classes", chemin: manipule_suivi_path, controleurs: %w[classes] }
    ]
    return onglets unless current_user&.admin?

    onglets << { libelle: "Les accès", chemin: manipule_acces_path, controleurs: %w[acces] }
  end

  def onglet_manipule_actif?(onglet)
    onglet[:controleurs].include?(controller_name)
  end

  # `pluralize` est sensible à la locale, et aucune inflexion n'est définie
  # pour le français : « 2 case » en sortait. Même parade que
  # `Mobile::ClassroomsHelper#eleves_label`, en un seul endroit.
  def au_pluriel(nombre, singulier, pluriel = nil)
    "#{nombre} #{nombre > 1 ? (pluriel || "#{singulier}s") : singulier}"
  end

  # « 1e » n'existe pas : c'est « 1er », puis « 2e », « 3e »… `ordinalize`
  # d'ActiveSupport parle anglais (« 1st ») et ne sert donc à rien ici.
  def rang_francais(nombre)
    nombre == 1 ? "1er" : "#{nombre}e"
  end

  # Ce qu'il fallait répondre, quel que soit le mode : l'étiquette cochée pour
  # un QCM, la réponse écrite pour une saisie. Lire ce qu'un enfant a répondu
  # sans savoir ce qui était attendu ne dit rien de son erreur.
  def reponse_attendue(probleme)
    return probleme.choices.detect(&:correct?)&.label if probleme.choix?

    [probleme.answer, probleme.unit].compact_blank.join(" ")
  end

  def chemin_audio(audio)
    return if audio.blank?

    manipule_audio_path(audio, v: audio.updated_at.to_i)
  end
end
