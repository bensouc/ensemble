# frozen_string_literal: true

# Une compétence d'un bloc de fiche de ceinture, et son exercice de ceinture.
# Les actions sur l'exercice sont celles de l'éditeur de plan de travail :
# en reprendre un (carrousel), en créer un vide, cloner celui qui y est.
class BeltSheetSkillsController < ApplicationController
  before_action :set_line, except: [:create]

  # Le retour du carrousel, annulé : la ligne telle qu'elle était.
  def show
    authorize @line.belt_sheet, :show?
  end

  def create
    @bloc = BeltSheetDomain.find(params[:belt_sheet_domain_id])
    authorize @bloc.belt_sheet, :update?
    # Une compétence de ce bloc, et d'aucun autre : même domaine, même ceinture.
    skill = Skill.find_by!(id: params.require(:skill_id), domain_id: @bloc.domain_id, level: @bloc.level)
    authorize skill, :show?
    @bloc.add_skill!(skill) unless @bloc.belt_sheet_skills.exists?(skill:)
    respond_with_bloc(t("fiches_ceinture.competence_ajoutee"))
  end

  # L'exercice choisi dans le carrousel : un exercice de ceinture de cette
  # compétence, qu'on a le droit de lire.
  def update
    authorize @line.belt_sheet, :update?
    challenge = Challenge.for_belt.find_by!(id: params.expect(belt_sheet_skill: [:challenge_id])[:challenge_id],
                                            skill_id: @line.skill_id)
    @line.update!(challenge: authorize(challenge, :show?))
    respond_with_line(t("fiches_ceinture.exercice_change"))
  end

  def destroy
    authorize @line.belt_sheet, :update?
    @bloc = @line.belt_sheet_domain
    @line.destroy
    respond_with_bloc(t("fiches_ceinture.competence_retiree"))
  end

  def move
    authorize @line.belt_sheet, :update?
    @line.insert_at(params[:position].to_i)
    head :no_content
  end

  def pick_challenge
    authorize @line.belt_sheet, :update?
    @challenges = autres_exercices
    return respond_with_line(t("fiches_ceinture.pas_d_autre_exercice")) if @challenges.empty?

    respond_to do |format|
      format.html { redirect_to belt_sheet_path(@line.belt_sheet) }
      format.turbo_stream
    end
  end

  def create_empty_challenge
    authorize @line.belt_sheet, :update?
    @line.update!(challenge: Challenge.create_empty(@line.skill, current_user, for_belt: true))
    respond_with_line(t("fiches_ceinture.exercice_vide_ajoute"))
  end

  # La copie garde la compétence et la liste de l'original, et prend sa place
  # sur la fiche — comme le « Cloner » du plan de travail.
  def clone_challenge
    authorize @line.belt_sheet, :update?
    original = authorize @line.challenge, :clone?
    copy = original.new_clone
    copy.user = current_user
    copy.save!
    @line.update!(challenge: copy)
    respond_with_line(t("fiches_ceinture.exercice_clone"))
  end

  private

  # Les exercices de ceinture de la compétence, sauf celui déjà sur la ligne.
  def autres_exercices
    Challenge.for_belt.includes(:rich_text_content).where(skill_id: @line.skill_id).
      where.not(id: @line.challenge_id).ordered.to_a
  end

  def set_line
    @line = BeltSheetSkill.includes(:skill, :challenge, belt_sheet_domain: :belt_sheet).find(params[:id])
  end

  def respond_with_line(message)
    flash.now[:notice] = message
    respond_to do |format|
      format.html { redirect_to belt_sheet_path(@line.belt_sheet) }
      format.turbo_stream { render "belt_sheet_skills/refresh" }
    end
  end

  def respond_with_bloc(message)
    flash.now[:notice] = message
    respond_to do |format|
      format.html { redirect_to belt_sheet_path(@bloc.belt_sheet) }
      format.turbo_stream { render "belt_sheet_skills/refresh_bloc" }
    end
  end
end
