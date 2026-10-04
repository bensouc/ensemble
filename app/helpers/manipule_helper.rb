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
  def chemin_audio(audio)
    return if audio.blank?

    manipule_audio_path(audio, v: audio.updated_at.to_i)
  end
end
