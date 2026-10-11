# frozen_string_literal: true

# La fiche de ceinture d'un élève. Elle se crée déjà garnie, depuis la fiche de
# l'élève : pour chaque domaine, la ceinture qui suit la dernière validée, avec
# ses compétences pas encore validées (`BeltSheet.prepare!`).
class BeltSheetsController < ApplicationController
  before_action :set_belt_sheet, only: [:show, :export, :destroy]

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
    @belt_sheet = BeltSheet.prepare!(student, current_user)
    redirect_to belt_sheet_path(@belt_sheet), notice: notice_preparation
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

  def set_belt_sheet
    @belt_sheet = BeltSheet.includes(belt_sheet_domains: [:domain, { belt_sheet_skills: [:skill, :challenge] }]).
      find(params[:id])
  end

  # Une fiche vide n'est pas une erreur — l'élève a peut-être tout validé, ou
  # n'a que des domaines spéciaux —, mais il faut le dire.
  def notice_preparation
    return t("fiches_ceinture.preparee") if @belt_sheet.belt_sheet_domains.any?

    t("fiches_ceinture.rien_a_preparer")
  end
end
