# frozen_string_literal: true

module Manipule
  # L'éditeur d'un problème : le formulaire, et l'aperçu de ce que l'élève
  # verra.
  #
  # L'aperçu n'est pas une maquette : c'est la vraie page de l'élève, rendue
  # par les mêmes gabarits et son propre habillage, posée dans un cadre. Une
  # imitation finirait par mentir le jour où l'une des deux changerait.
  class ProblemesController < ProfController
    before_action :set_competence, only: %i[new create apercu]
    before_action :set_probleme, only: %i[edit update destroy dupliquer]

    CHOIX_PAR_PROBLEME = 3

    def new
      authorize @competence, :create?, policy_class: ProblemPolicy
      @probleme = Problem.new(skill: @competence, answer_mode: "choix")
      CHOIX_PAR_PROBLEME.times { |rang| @probleme.choices.build(position: rang + 1) }
    end

    def edit
      authorize @probleme
      completer_les_choix
    end

    def create
      authorize @competence, :create?, policy_class: ProblemPolicy
      @probleme = Problem.new(attributs.merge(skill: @competence, user: current_user,
                                              position: prochaine_position))
      return render(:new, status: :unprocessable_content) unless @probleme.save

      redirect_to manipule_banque_competence_path(@competence), notice: t("manipule.probleme_cree")
    end

    def update
      authorize @probleme
      unless @probleme.update(attributs)
        completer_les_choix
        return render(:edit, status: :unprocessable_content)
      end

      redirect_to manipule_banque_competence_path(@probleme.skill), notice: t("manipule.probleme_enregistre")
    end

    # Un problème déjà passé par un élève ne se supprime pas : son historique
    # ferait mentir le suivi. Le modèle le refuse, on le dit plutôt que de
    # laisser une erreur 500 l'expliquer.
    def destroy
      authorize @probleme
      competence = @probleme.skill
      if @probleme.destroy
        redirect_to manipule_banque_competence_path(competence), notice: t("manipule.probleme_supprime")
      else
        redirect_to manipule_banque_competence_path(competence), alert: t("manipule.probleme_deja_travaille")
      end
    end

    # Écrire dix problèmes qui ne diffèrent que par leurs nombres est le
    # quotidien de l'enseignante. La copie part en brouillon : elle n'est pas
    # relue, et une banque ne doit jamais se remplir toute seule.
    def dupliquer
      authorize @probleme, :create?
      copie = @probleme.dup
      copie.assign_attributes(published: false, user: current_user, position: prochaine_position(@probleme.skill))
      @probleme.choices.each { |choix| copie.choices.build(choix.slice(:label, :correct, :position)) }
      copie.save!

      redirect_to manipule_edition_probleme_path(copie), notice: t("manipule.probleme_duplique")
    end

    # Rendu dans le gabarit de l'élève, pour que l'aperçu ait sa feuille de
    # style et son JavaScript — les jetons se déplacent pour de vrai.
    def apercu
      authorize @competence, :create?, policy_class: ProblemPolicy
      @probleme = Problem.new(attributs.merge(skill: @competence))
      @choix = @probleme.choices.reject { |choix| choix.label.blank? }
      render layout: "manipule"
    end

    private

    def set_competence
      @competence = Skill.find(params[:skill_id])
    end

    def set_probleme
      @probleme = Problem.find(params[:id])
    end

    def prochaine_position(competence = @competence)
      (Problem.where(skill: competence).maximum(:position) || 0) + 1
    end

    # Un formulaire enregistré alors qu'un choix a été vidé revient avec moins
    # de trois cases : on les remet, sinon l'enseignante perd des champs sans
    # comprendre pourquoi.
    def completer_les_choix
      manquants = CHOIX_PAR_PROBLEME - @probleme.choices.size
      manquants.times { |rang| @probleme.choices.build(position: @probleme.choices.size + rang + 1) }
    end

    def attributs
      base = params.expect(
        probleme: [:statement, :question, :answer_mode, :answer, :unit, :tool,
                   { choices_attributes: %i[id label position] }]
      ).to_h

      base["choices_attributes"] = choix_avec_la_bonne(base["choices_attributes"])
      base["tool_data"] = reglages
      base
    end

    # La bonne réponse est un bouton radio, pas trois cases à cocher : le
    # modèle exige exactement une bonne réponse, et trois cases permettent d'en
    # cocher zéro ou trois. La contrainte est portée par le formulaire lui-même.
    def choix_avec_la_bonne(choix)
      return {} if choix.blank?

      bonne = params[:probleme][:bonne_reponse].to_s
      choix.each { |rang, attributs| attributs["correct"] = (rang.to_s == bonne) }
    end

    # Les réglages de l'outil arrivent à plat et repartent dans la colonne
    # structurée. Sans outil choisi, on n'y laisse rien traîner.
    def reglages
      return {} if params[:probleme][:tool].blank?

      brut = params[:probleme].fetch(:reglages, {})
      { "ressource" => brut[:ressource].presence || "pomme",
        "reserve" => brut[:reserve].to_i,
        "zones" => Array(brut[:zones]).map { |zone| zone.to_s.strip }.reject(&:empty?) }
    end
  end
end
