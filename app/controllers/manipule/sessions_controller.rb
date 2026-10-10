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
    def destroy
      classe = eleve_courant&.classroom
      fermer_session_eleve
      return redirect_to(new_user_session_path) if params[:vers] == "ensemble"

      jeton = classe && ClassroomToken.find_by(classroom: classe)
      redirect_to jeton ? manipule_classe_path(token: jeton.token) : root_path
    end

    private

    def set_classe
      return if action_name == "destroy"

      jeton = ClassroomToken.find_by(token: params[:token])
      @classe = jeton&.classroom
      render :adresse_inconnue, status: :not_found if @classe.nil?
    end
  end
end
