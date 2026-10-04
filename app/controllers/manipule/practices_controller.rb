# frozen_string_literal: true

module Manipule
  # La série : un problème à la fois, une réponse, et on enchaîne.
  class PracticesController < EleveController
    before_action :exiger_eleve!

    def show
      @serie = reprendre_ou_commencer
      return render(:rien_a_faire) if @serie.nil?
      return render(:verdict) if verdict_a_montrer

      @tentative = @serie.attempts.detect { |tentative| !tentative.repondue? }
      return redirect_to(manipule_fin_path) if @tentative.nil?

      preparer_le_probleme(@tentative)
    end

    # On repart en GET plutôt que de rendre la réponse : un enfant qui
    # rafraîchit son écran ne doit pas renvoyer sa réponse.
    def repondre
      tentative = tentative_courante
      return redirect_to(manipule_serie_path) if tentative.nil?

      enregistrer(tentative)
      redirect_to manipule_serie_path(vu: tentative.id)
    end

    # Compter les réécoutes ne coûte rien, et dit à l'enseignante qui bute sur
    # la lecture plutôt que sur les mathématiques.
    def ecouter
      tentative_courante&.ecoute!
      head :no_content
    end

    def fin
      @serie = Practice.where(student: eleve_courant).order(:created_at).last
      @serie&.terminer! unless @serie&.terminee?
    end

    private

    def preparer_le_probleme(tentative)
      @probleme = tentative.problem
      # Mélangées à chaque affichage : la place d'une réponse ne dit rien.
      @choix = @probleme.choices.shuffle
      charger_audios
    end

    # Deux requêtes plutôt qu'une : la relation est polymorphe, et un `IN` sur
    # deux types différents ne se dit pas simplement.
    def charger_audios
      @audios_probleme = Audio.where(readable: @probleme).index_by(&:role)
      @audios_choix = Audio.where(readable: @choix).index_by(&:readable_id)
    end

    def verdict_a_montrer
      return nil if params[:vu].blank?

      @tentative = @serie.attempts.detect { |tentative| tentative.id == params[:vu].to_i && tentative.repondue? }
      @probleme = @tentative&.problem
      @tentative
    end

    def enregistrer(tentative)
      if params[:passer].present?
        tentative.passer!
      elsif (choix = tentative.problem.choices.find_by(id: params[:choice_id]))
        tentative.repondre_par_choix!(choix)
      elsif params[:saisie].present?
        tentative.repondre_par_saisie!(params[:saisie])
      end
    end

    def tentative_courante
      Attempt.joins(:practice).
        where(manipule_practices: { student_id: eleve_courant.id }).
        find_by(id: params[:attempt_id])
    end

    # Une série en cours se reprend, sinon on en commence une sur la compétence
    # que l'enseignante a désignée. Sans affectation ou sans banque, rien à
    # faire — et on le dit, plutôt que de lever une exception devant l'élève.
    def reprendre_ou_commencer
      affectation = Assignment.courante(eleve_courant)
      return nil if affectation.nil?

      en_cours = Practice.where(student: eleve_courant, skill: affectation.skill, finished_at: nil).
        order(:created_at).last
      return en_cours if en_cours

      return nil unless Problem.published.exists?(skill: affectation.skill)

      Practice.commencer!(student: eleve_courant, skill: affectation.skill)
    end
  end
end
