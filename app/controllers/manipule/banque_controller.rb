# frozen_string_literal: true

module Manipule
  # La banque, côté enseignante : ce qu'elle a écrit, et ce qui circule.
  #
  # Pas de gabarit à part : ces pages sont Ensemble, elle y arrive connectée,
  # avec la barre et les styles qu'elle connaît.
  class BanqueController < ProfController
    before_action :set_competence, except: [:index, :circulation]
    before_action :set_probleme, only: [:circulation]
    before_action :exiger_fichier, only: [:importer]

    # Une école porte plus de mille compétences : aucune liste plate ne tient.
    # Sans filtre, on ne montre que celles où elle a déjà écrit — son travail.
    # Dès qu'un filtre est posé, on montre tout le périmètre demandé, y compris
    # les compétences vides : c'était le seul chemin vers un PREMIER problème,
    # et il n'existait nulle part. Une compétence sans problème n'apparaissait
    # pas, donc on ne pouvait pas commencer.
    def index
      @problemes = policy_scope(Problem).includes(skill: { domain: :grade })
      @filtre = filtre?
      @niveaux = Grade.where(school: current_user.school).order(:grade_level)
      @domaines = domaines_du_filtre
      @competences = competences_affichees
      @compte = policy_scope(Problem).where(skill_id: @competences.map(&:id))
                                     .group(:skill_id, :published).count
    end

    def show
      authorize @competence, :show?, policy_class: ProblemPolicy
      @problemes = Problem.where(skill: @competence).includes(:choices).order(:position, :id)
    end

    def import
      authorize @competence, :importer?, policy_class: ProblemPolicy
    end

    def importer
      authorize @competence, :importer?, policy_class: ProblemPolicy
      @import = Import.new(skill: @competence, user: current_user, fichier:).executer!
      return render(:import, status: :unprocessable_content) unless @import.reussi?

      flash[:notice] = t("manipule.importes", nombre: @import.problemes.count)
      redirect_to manipule_banque_competence_path(@competence)
    end

    def publier
      authorize @competence, :publier?, policy_class: ProblemPolicy
      nombre = Problem.where(skill: @competence, published: false).count
      Problem.where(skill: @competence, published: false).find_each { |probleme| probleme.update!(published: true) }
      flash[:notice] = t("manipule.rendus_visibles", nombre:)
      redirect_to manipule_banque_competence_path(@competence)
    end

    def circulation
      authorize @probleme, :publier?
      @probleme.update!(published: !@probleme.published)
      redirect_to manipule_banque_competence_path(@probleme.skill)
    end

    private

    FILTRES = %i[niveau domaine ceinture].freeze

    def filtre?
      FILTRES.any? { |nom| params[nom].present? }
    end

    # Son école passe par `school_role`. Le `school_id` d'une compétence et
    # celui du niveau de son domaine peuvent désigner deux écoles différentes :
    # on exige les deux, sans quoi une compétence fuit d'une école à l'autre.
    def competences_de_son_ecole
      Skill.joins(domain: :grade)
           .where(school_id: current_user.school&.id)
           .where(grades: { school_id: current_user.school&.id })
    end

    # Les domaines proposés suivent le niveau choisi. Tant qu'aucun niveau n'est
    # posé, ils sont tous là — deux écoles n'ont jamais les mêmes.
    #
    # Rendus groupés par niveau : chaque niveau porte ses propres domaines, et
    # ils portent les mêmes noms. À plat, la liste alignait quatre « Calcul »
    # indiscernables. Les groupes suivent l'ordre scolaire, pas l'alphabet —
    # sans quoi le CP tomberait après le CM2.
    def domaines_du_filtre
      portee = Domain.joins(:grade).preload(:grade)
                     .where(grades: { school_id: current_user.school&.id })
      portee = portee.where(grade_id: params[:niveau]) if params[:niveau].present?
      portee.order(:name)
            .group_by(&:grade)
            .sort_by { |niveau, _| Classroom::GRADE.index(niveau&.grade_level) || Classroom::GRADE.size }
            .map { |niveau, domaines| [niveau&.name.to_s, domaines.map { |domaine| [domaine.name, domaine.id] }] }
    end

    def competences_affichees
      return @problemes.map(&:skill).uniq.sort_by { |competence| [competence.level, competence.name] } unless @filtre

      portee = competences_de_son_ecole.preload(domain: :grade)
      portee = portee.where(grades: { id: params[:niveau] }) if params[:niveau].present?
      portee = portee.where(domain_id: params[:domaine]) if params[:domaine].present?
      portee = portee.where(level: params[:ceinture]) if params[:ceinture].present?
      portee.order(:level, :name).to_a
    end

    def fichier
      params[:fichier]
    end

    def exiger_fichier
      return if fichier.present?

      flash[:alert] = t("manipule.fichier_manquant")
      redirect_to manipule_banque_import_path(@competence)
    end

    def set_competence
      @competence = Skill.find(params[:skill_id])
    end

    def set_probleme
      @probleme = Problem.find(params[:id])
    end
  end
end
