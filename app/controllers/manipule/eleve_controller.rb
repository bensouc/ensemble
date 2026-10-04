# frozen_string_literal: true

module Manipule
  # Base de tout ce que voit l'élève. Il n'a pas de compte : son identité tient
  # dans un cookie signé, limité au chemin /manipule.
  #
  # Deux menaces ont dicté ce qui suit. Un élève qui remonterait vers Ensemble
  # tomberait sur un formulaire de connexion, impasse pour un enfant de six ans.
  # Et surtout : la session de l'enseignante restée ouverte sur l'ordinateur du
  # fond de la classe — là, l'élève n'a rien à contourner, il tape l'adresse
  # d'Ensemble et il EST sa maîtresse. D'où l'exclusion mutuelle ci-dessous.
  class EleveController < ApplicationController
    COOKIE_ELEVE = :manipule_eleve
    # Marqueur sans identité, posé à la racine, et qui ne sert qu'à renvoyer un
    # élève égaré vers son écran. Le cookie qui dit QUI il est, lui, ne sort
    # jamais de /manipule.
    COOKIE_MARQUEUR = :manipule_en_cours

    layout "manipule"

    skip_before_action :authenticate_user!, raise: false
    skip_before_action :renvoyer_les_eleves_vers_manipule, raise: false
    skip_after_action :verify_authorized, raise: false
    skip_after_action :verify_policy_scoped, raise: false

    helper_method :eleve_courant

    private

    def eleve_courant
      return @eleve_courant if defined?(@eleve_courant)

      @eleve_courant = Student.find_by(id: cookies.signed[COOKIE_ELEVE])
    end

    def exiger_eleve!
      render :perdu, status: :ok if eleve_courant.nil?
    end

    # Entrer en élève déconnecte l'enseignante : une session est la sienne ou
    # celle d'un élève, jamais les deux. Elle se reconnectera après la séance,
    # et sur une machine partagée c'est plutôt une bonne nouvelle.
    def ouvrir_session_eleve(student)
      sign_out(:user) if user_signed_in?
      cookies.signed[COOKIE_ELEVE] = { value: student.id, path: "/manipule", httponly: true, same_site: :lax }
      cookies[COOKIE_MARQUEUR] = { value: "1", path: "/", httponly: true, same_site: :lax }
      @eleve_courant = student
    end

    def fermer_session_eleve
      cookies.delete(COOKIE_ELEVE, path: "/manipule")
      cookies.delete(COOKIE_MARQUEUR, path: "/")
      @eleve_courant = nil
    end
  end
end
