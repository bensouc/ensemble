# frozen_string_literal: true

module Manipule
  # L'entrée : une adresse par classe, la liste des prénoms, un clic.
  #
  # Pas de mot de passe — un code par élève ferait échouer un CP, et
  # l'enseignante a confirmé que cliquer son prénom, il sait faire. Ce que ça
  # n'empêche pas : qui possède l'adresse peut se faire passer pour n'importe
  # quel élève de la classe. Ce qui est exposé, ce sont des prénoms et des
  # résultats d'entraînement, et le jeton se renouvelle.
  class SessionsController < EleveController
    before_action :set_classe

    def new
      @eleves = @classe.students.order(:first_name)
    end

    def create
      eleve = @classe.students.find(params.require(:student_id))
      ouvrir_session_eleve(eleve)
      redirect_to manipule_serie_path
    end

    # Deux sorties, une seule mécanique : on efface d'abord la session de
    # l'élève, toujours.
    #
    # Celle de l'enfant ramène à la liste des prénoms — il ne quitte jamais
    # /manipule. Celle de l'adulte (`vers=ensemble`) mène à la connexion
    # d'Ensemble : une enseignante qui ouvre le lien de sa classe sur SA
    # machine en est déconnectée — c'est voulu, une session est la sienne ou
    # celle d'un élève — et tant que le marqueur vivait, chaque adresse
    # d'Ensemble la renvoyait à la séance. Elle était enfermée dans le jeu.
    #
    # La porte de l'adulte peut être fermée par un code (réglé dans Manipule,
    # pour la classe) : sans le bon code, on reste dans le jeu, la session de
    # l'élève intacte. Sans classe connue — l'écran « pas encore entré » —, elle
    # reste libre.
    def destroy
      classe = classe_quittee
      return refuser_la_porte(classe) if vers_ensemble? && !porte_ouverte?(classe)

      fermer_session_eleve
      redirect_to vers_ensemble? ? new_user_session_path : liste_des_prenoms(classe)
    end

    private

    def vers_ensemble?
      params[:vers] == "ensemble"
    end

    # La classe qu'on quitte : celle de l'élève, ou celle de l'adresse quand
    # personne n'est entré (la porte de l'écran des prénoms).
    def classe_quittee
      eleve_courant&.classroom || ClassroomToken.find_by(token: params[:token].to_s)&.classroom
    end

    def liste_des_prenoms(classe)
      jeton = classe && ClassroomToken.find_by(classroom: classe)
      jeton ? manipule_classe_path(token: jeton.token) : root_path
    end

    def porte_ouverte?(classe)
      jeton = classe && ClassroomToken.find_by(classroom: classe)
      jeton.nil? || jeton.porte_ouverte?(params[:code_prof])
    end

    def refuser_la_porte(classe)
      jeton = ClassroomToken.find_by(classroom: classe)
      redirect_to manipule_classe_path(token: jeton.token), alert: t("manipule.code_incorrect")
    end

    def set_classe
      return if action_name == "destroy"

      @jeton = ClassroomToken.find_by(token: params[:token])
      @classe = @jeton&.classroom
      render :adresse_inconnue, status: :not_found if @classe.nil?
    end
  end
end
