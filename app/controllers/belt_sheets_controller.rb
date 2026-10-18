# frozen_string_literal: true

# La fiche de ceinture d'un élève. Elle se crée déjà garnie, au choix : ses
# ceintures en cours, ou selon ses résultats (`BeltSheet.prepare!`). Ou une
# fiche d'aucun élève, générée depuis les exercices de ceinture
# (`BeltSheet.generer!`).
class BeltSheetsController < ApplicationController
  before_action :set_belt_sheet, only: [:show, :export, :update, :clone, :destroy]
  # Une liste, comme `index` : elle passe par la Scope, pas par `authorize`.
  skip_after_action :verify_authorized, only: :non_assignees
  after_action :verify_policy_scoped, only: :non_assignees

  # Voir > Ceintures : les classes qui ont ouvert les fiches de ceinture, un
  # dossier par élève — la présentation de Voir > Plans de travail.
  def index
    @classrooms = classes_aux_fiches
    @sheets_by_student = policy_scope(BeltSheet).includes(:belt_sheet_domains).
      where(student: Student.where(classroom: @classrooms)).
      order(created_at: :desc).group_by(&:student_id)
  end

  # Voir > Ceintures > Non assignées : les fiches générées depuis les exercices
  # de ceinture, celles de l'enseignant seulement, un dossier par niveau.
  def non_assignees
    @sheets_by_grade = policy_scope(BeltSheet).non_assignees.where(user: current_user).
      includes(:grade, belt_sheet_domains: :domain).order(created_at: :desc).
      group_by(&:grade).sort_by { |grade, _| Classroom::GRADE.index(grade.grade_level) || Classroom::GRADE.size }
  end

  def show
    authorize @belt_sheet
    respond_to do |format|
      format.html
      # `inline` : le PDF s'ouvre dans l'onglet de la page d'attente, où la
      # visionneuse offre Imprimer et Enregistrer.
      format.pdf do
        pdf = PdfGenerator::BeltSheetPdf.new(@belt_sheet)
        send_data pdf.generate, filename: "#{pdf.title}.pdf", type: "application/pdf", disposition: "inline"
      end
    end
  end

  def export
    authorize @belt_sheet, :show?
    render layout: false
  end

  def create
    student = Student.find(params[:student_id])
    authorize BeltSheet.new(student:)
    # Le sélecteur de la modale : les ceintures de ses plans, ou ses prochaines.
    mode = BeltSheet::MODES.include?(params[:mode]) ? params[:mode] : "resultats"
    @belt_sheet = BeltSheet.prepare!(student, current_user, domains: domaines_choisis(student), mode:)
    redirect_to belt_sheet_path(@belt_sheet), notice: notice_preparation
  end

  # Le nom de la fiche, depuis la modale de l'éditeur — comme celui d'un plan
  # de travail. Vide, la fiche reprend son nom par défaut.
  def update
    authorize @belt_sheet
    @belt_sheet.update!(params.expect(belt_sheet: [:name]))
    redirect_to belt_sheet_path(@belt_sheet), notice: t("fiches_ceinture.renommee"), status: :see_other
  end

  # Le niveau, le domaine et la ceinture des filtres des exercices de ceinture.
  # La fiche s'ouvre dans l'éditeur, comme celle d'un élève : on la retouche,
  # puis le bouton PDF en montre le rendu.
  def generer
    grade = Grade.find(params[:grade_id])
    authorize BeltSheet.new(grade:, user: current_user), :create?
    return head(:unprocessable_content) unless ceinture_demandee

    # Un domaine de ce niveau : sans quoi la fiche se garnissait des
    # compétences d'une autre école.
    @belt_sheet = BeltSheet.generer!(grade, grade.domains.find(params[:domain_id]), ceinture_demandee, current_user)
    redirect_to belt_sheet_path(@belt_sheet), notice: notice_generation, status: :see_other
  end

  # Une copie pour chaque élève coché — parmi les candidats seulement : un id pris
  # tel quel clonerait la fiche vers un élève d'une autre classe, ou d'une
  # classe qui n'a pas ouvert les fiches de ceinture.
  def clone
    authorize @belt_sheet
    eleves = @belt_sheet.clone_candidates(current_user).where(id: Array(params.dig(:clone, :student_ids)).compact_blank)
    eleves.each { |eleve| @belt_sheet.clone_for!(eleve, current_user) }
    redirect_to belt_sheets_path, notice: notice_clonage(eleves), status: :see_other
  end

  def destroy
    authorize @belt_sheet
    @belt_sheet.destroy
    options = { notice: t("fiches_ceinture.supprimee"), status: :see_other }
    # Depuis l'éditeur, la fiche n'existe plus : on revient à sa liste.
    return redirect_to(retour_apres_suppression, **options) if depuis_l_editeur?

    respond_to do |format|
      # Depuis une liste, seule la ligne s'en va, comme celle d'un plan de
      # travail. La redirection rechargeait la page, et refermait le dossier.
      format.turbo_stream do
        @dossier, @restantes = dossier_et_fiches_restantes
        flash.now[:notice] = options[:notice]
      end
      format.html { redirect_back_or_to retour_apres_suppression, **options }
    end
  end

  private

  # Ses classes d'abord, puis celles qu'on lui partage, chacune par niveau —
  # l'ordre de la liste des classes. Celles qui ont ouvert les fiches seulement.
  def classes_aux_fiches
    siennes = current_user.classrooms.where(belt_sheets: true).includes(:grade)
    partagees = current_user.user_shared_classrooms.where(belt_sheets: true).includes(:grade)
    (Classroom.par_niveau(siennes) + Classroom.par_niveau(partagees)).uniq
  end

  # Le bouton Supprimer de l'éditeur : on vient de la page de la fiche.
  def depuis_l_editeur?
    request.referer.to_s.include?(belt_sheet_path(@belt_sheet))
  end

  # Les domaines cochés dans la modale, parmi ceux du niveau de l'élève — un id
  # pris tel quel garnirait la fiche des compétences d'une autre école. Sans
  # modale (aucun paramètre), la préparation choisit elle-même.
  def domaines_choisis(student)
    ids = params.dig(:belt_sheet, :domain_ids)
    return nil if ids.nil?

    student.grade.domains.where(id: Array(ids).compact_blank).to_a
  end

  # Le dossier de la liste où la fiche était rangée — son élève, ou son niveau
  # pour une fiche non assignée —, et le nombre de fiches qu'il lui reste.
  def dossier_et_fiches_restantes
    fiches = policy_scope(BeltSheet)
    if @belt_sheet.non_assignee?
      [@belt_sheet.grade, fiches.non_assignees.where(user: current_user, grade: @belt_sheet.grade).count]
    else
      [@belt_sheet.student, fiches.where(student: @belt_sheet.student).count]
    end
  end

  # La progression de l'élève ; la liste des fiches non assignées, sans élève.
  def retour_apres_suppression
    @belt_sheet.non_assignee? ? non_assignees_belt_sheets_path : student_path(@belt_sheet.student)
  end

  def set_belt_sheet
    @belt_sheet = BeltSheet.includes(belt_sheet_domains: [:domain, { belt_sheet_skills: [:skill, :challenge] }]).
      find(params[:id])
  end

  def notice_clonage(eleves)
    return t("fiches_ceinture.aucun_eleve_coche") if eleves.empty?

    t("fiches_ceinture.clonee", eleves: eleves.map(&:first_name).to_sentence)
  end

  # La ceinture des filtres, si elle existe.
  def ceinture_demandee
    params[:level].to_i.presence_in(1..Belt::BELT_COLORS.size)
  end

  # Un domaine spécial arrive vide : c'est au professeur de construire la fiche.
  def notice_generation
    t(@belt_sheet.belt_sheet_skills.any? ? "fiches_ceinture.generee" : "fiches_ceinture.generee_vide")
  end

  # Une fiche vide n'est pas une erreur — l'élève a peut-être tout validé, ou
  # n'a que des domaines spéciaux —, mais il faut le dire.
  def notice_preparation
    return t("fiches_ceinture.preparee") if @belt_sheet.belt_sheet_domains.any?

    t("fiches_ceinture.rien_a_preparer")
  end
end
