# frozen_string_literal: true

# La fiche de ceinture d'un élève. Elle se crée déjà garnie, depuis la fiche de
# l'élève : pour chaque domaine, la ceinture qui suit la dernière validée, avec
# ses compétences pas encore validées (`BeltSheet.prepare!`).
class BeltSheetsController < ApplicationController
  before_action :set_belt_sheet, only: [:show, :destroy]

  def show
    authorize @belt_sheet
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
    redirect_to student_path(student), notice: t("fiches_ceinture.supprimee"), status: :see_other
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
