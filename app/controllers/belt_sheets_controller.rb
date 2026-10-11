# frozen_string_literal: true

# La fiche de ceinture d'un élève. Elle se crée déjà garnie, au choix : ses
# ceintures en cours, ou selon ses résultats (`BeltSheet.prepare!`).
class BeltSheetsController < ApplicationController
  before_action :set_belt_sheet, only: [:show, :export, :clone, :destroy]

  # Voir > Ceintures : les classes qui ont ouvert les fiches de ceinture, un
  # dossier par élève — la présentation de Voir > Plans de travail.
  def index
    partagees = current_user.user_shared_classrooms.where(belt_sheets: true)
    @classrooms = (current_user.classrooms.where(belt_sheets: true) + partagees).
      uniq.sort_by(&:created_at)
    @sheets_by_student = policy_scope(BeltSheet).includes(:belt_sheet_domains).
      where(student: Student.where(classroom: @classrooms)).
      order(created_at: :desc).group_by(&:student_id)
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

  # Une copie pour chaque élève coché — parmi les candidats seulement : un id pris
  # tel quel clonerait la fiche vers un élève d'une autre classe, ou d'une
  # classe qui n'a pas ouvert les fiches de ceinture.
  def clone
    authorize @belt_sheet, :show?
    eleves = @belt_sheet.clone_candidates(current_user).where(id: Array(params.dig(:clone, :student_ids)).compact_blank)
    eleves.each { |eleve| @belt_sheet.clone_for!(eleve, current_user) }
    redirect_to belt_sheets_path, notice: notice_clonage(eleves), status: :see_other
  end

  def destroy
    authorize @belt_sheet
    student = @belt_sheet.student
    @belt_sheet.destroy
    # On revient d'où l'on vient — la liste des fiches, la progression de
    # l'élève —, sauf de la fiche elle-même, qui n'existe plus.
    options = { notice: t("fiches_ceinture.supprimee"), status: :see_other }
    if request.referer.to_s.include?(belt_sheet_path(@belt_sheet))
      redirect_to student_path(student), **options
    else
      redirect_back_or_to student_path(student), **options
    end
  end

  private

  # Les domaines cochés dans la modale, parmi ceux du niveau de l'élève — un id
  # pris tel quel garnirait la fiche des compétences d'une autre école. Sans
  # modale (aucun paramètre), la préparation choisit elle-même.
  def domaines_choisis(student)
    ids = params.dig(:belt_sheet, :domain_ids)
    return nil if ids.nil?

    student.grade.domains.where(id: Array(ids).compact_blank).to_a
  end

  def set_belt_sheet
    @belt_sheet = BeltSheet.includes(belt_sheet_domains: [:domain, { belt_sheet_skills: [:skill, :challenge] }]).
      find(params[:id])
  end

  def notice_clonage(eleves)
    return t("fiches_ceinture.aucun_eleve_coche") if eleves.empty?

    t("fiches_ceinture.clonee", eleves: eleves.map(&:first_name).to_sentence)
  end

  # Une fiche vide n'est pas une erreur — l'élève a peut-être tout validé, ou
  # n'a que des domaines spéciaux —, mais il faut le dire.
  def notice_preparation
    return t("fiches_ceinture.preparee") if @belt_sheet.belt_sheet_domains.any?

    t("fiches_ceinture.rien_a_preparer")
  end
end
