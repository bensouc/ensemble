# frozen_string_literal: true

module Manipule
  # Le domaine « Autre » : ranger une manipulation qui ne relève d'aucune
  # compétence d'Ensemble, sans la laisser flotter.
  #
  # L'enseignante y nomme ses propres compétences, à la ceinture qu'elle
  # choisit. Le domaine se crée tout seul à la première, par niveau.
  class AutreController < ProfController
    def index
      @niveaux = niveaux_de_ses_classes
      @competences = competences_par_niveau
      @compte = policy_scope(Problem).where(skill_id: @competences.values.flatten.map(&:id)).
        group(:skill_id).count
    end

    def create
      niveau = son_niveau!
      # L'autorisation porte sur une compétence de SON école — inutile de créer
      # le domaine pour la demander.
      authorize Skill.new(school: niveau.school), :create?, policy_class: ProblemPolicy
      DomaineAutre.ajouter_competence!(niveau:, nom: params[:nom], ceinture: params[:ceinture])
      redirect_to manipule_autre_path, notice: t("manipule.competence_autre_creee")
    rescue ActiveRecord::RecordInvalid => e
      # Un nom vide ne doit pas montrer une page d'erreur : on redit ce qui
      # manque, et le domaine n'a pas été créé pour rien.
      redirect_to manipule_autre_path, alert: e.record.errors.full_messages.to_sentence
    end

    private

    # Un niveau qui n'est pas le sien n'existe pas pour elle : on lève le même
    # refus que partout ailleurs, mis en forme par `ApplicationController`,
    # plutôt qu'une 404 qu'elle ne saurait pas lire.
    def son_niveau!
      niveaux_de_ses_classes.find_by(id: params[:grade_id]) || raise(Pundit::NotAuthorizedError)
    end

    # Les niveaux de ses classes, comme partout ailleurs dans Manipule.
    def niveaux_de_ses_classes
      Grade.where(id: policy_scope(Classroom).select(:grade_id)).order(:grade_level)
    end

    def competences_par_niveau
      @niveaux.index_with do |niveau|
        domaine = DomaineAutre.pour(niveau)
        domaine ? Skill.where(domain: domaine).order(:level, :name).to_a : []
      end
    end
  end
end
