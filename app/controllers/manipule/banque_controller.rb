# frozen_string_literal: true

module Manipule
  # La banque, côté enseignante : ce qu'elle a écrit, et ce qui circule.
  #
  # Pas de gabarit à part : ces pages sont Ensemble, elle y arrive connectée,
  # avec la barre et les styles qu'elle connaît.
  class BanqueController < ApplicationController
    before_action :set_competence, except: [:index, :circulation]
    before_action :set_probleme, only: [:circulation]
    before_action :exiger_fichier, only: [:importer]

    def index
      @problemes = policy_scope(Problem).includes(skill: :domain)
      @par_competence = @problemes.group_by(&:skill).sort_by { |competence, _| [competence.level, competence.name] }
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
      flash[:notice] = t("manipule.mis_en_circulation", nombre:)
      redirect_to manipule_banque_competence_path(@competence)
    end

    def circulation
      authorize @probleme, :publier?
      @probleme.update!(published: !@probleme.published)
      redirect_to manipule_banque_competence_path(@probleme.skill)
    end

    private

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
