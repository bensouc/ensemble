# frozen_string_literal: true

module Manipule
  # Le suivi d'une classe, côté enseignante : ce que chaque élève travaille, et
  # ce que ça a donné. C'est aussi d'ici qu'elle désigne la compétence du jour,
  # sans quoi l'élève tombe sur « Rien à faire pour le moment ».
  class ClassesController < ApplicationController
    before_action :set_classe, except: [:index]

    def index
      @classes = policy_scope(Classroom).includes(:students).order(:name)
    end

    def show
      authorize @classe, :show?
      @jeton = ClassroomToken.pour!(@classe)
      @competences = competences_disponibles
      @eleves = @classe.students.order(:first_name)
      @affectations = Assignment.active.where(student: @eleves).index_by(&:student_id)
      @dernieres = dernieres_series(@eleves)
      @qui_coince = qui_coince
    end

    def affecter
      authorize @classe, :update?
      competence = Skill.find(params.require(:skill_id))
      cibles = cibles_de(params[:student_id])
      cibles.each { |eleve| Assignment.designer!(student: eleve, skill: competence, user: current_user) }
      flash[:notice] = t("manipule.affectes", nombre: cibles.size, competence: competence.name)
      redirect_to manipule_suivi_classe_path(@classe)
    end

    # Renouveler ferme aussitôt l'ancienne adresse : c'est le seul recours quand
    # un lien a circulé plus loin que la classe.
    def jeton
      authorize @classe, :update?
      ClassroomToken.pour!(@classe).renouveler!
      flash[:notice] = t("manipule.jeton_renouvele")
      redirect_to manipule_suivi_classe_path(@classe)
    end

    private

    def set_classe
      @classe = Classroom.find(params[:id])
    end

    # Un élève nommé, ou toute la classe. La recherche part des élèves de CETTE
    # classe : un identifiant venu d'ailleurs ne désigne rien.
    def cibles_de(student_id)
      return @classe.students if student_id.blank?

      [@classe.students.find(student_id)]
    end

    # Les compétences du niveau de la classe qui ont au moins un problème en
    # circulation : désigner une compétence vide mènerait l'élève à un écran
    # vide, et elle n'aurait aucun moyen de comprendre pourquoi.
    def competences_disponibles
      Skill.where(domain: @classe.grade.domains).
        where(id: Problem.published.select(:skill_id)).
        order(:level, :name)
    end

    def dernieres_series(eleves)
      Practice.where(student: eleves).
        includes(:skill, attempts: :problem).
        order(:created_at).
        index_by(&:student_id)
    end

    # Les problèmes sur lesquels la classe bute, tous élèves confondus. C'est ce
    # qu'elle a demandé en Q43 : savoir où ça a coincé, pas seulement qui a raté.
    def qui_coince
      Attempt.joins(:practice).
        where(manipule_practices: { student_id: @classe.students.select(:id) }).
        where(status: %w[wrong skipped]).
        group(:problem_id).
        order(count_all: :desc).
        limit(5).
        count.
        filter_map { |problem_id, nombre| [Problem.find_by(id: problem_id), nombre] if problem_id }
    end
  end
end
