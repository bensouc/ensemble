# frozen_string_literal: true

class ModalsController < ApplicationController
  # Les trois modales montrent ou préparent le travail d'un élève : réservées à
  # qui voit sa classe, comme sa fiche (`StudentPolicy#show?`).
  def auto_gen
    @student = authorize Student.includes(:classroom).find(params[:id]), :show?
    @domains = @student.classroom.grade.domains.sort_by(&:position)
    @checked_domains = AutoGenExclusion.auto_domains(@domains, user: current_user)
  end

  # Création rapide d'un plan de travail depuis la liste des plans de travail :
  # une seule modale, deux issues — un plan vierge ou un plan auto-généré sur le
  # niveau de l'élève. Les deux réutilisent les mécaniques existantes
  # (`work_plans#create` et `work_plans#auto_new_wp`).
  def new_work_plan
    @student = authorize Student.includes(classroom: :grade).find(params[:id]), :show?
    @work_plan = new_work_plan_for(@student)
    @domains = @student.classroom.grade.domains.sort_by(&:position)
    @checked_domains = AutoGenExclusion.auto_domains(@domains, user: current_user)
  end

  # Nouvelle fiche de ceinture : deux façons de préparer — les ceintures prévues
  # dans ses plans, ou ses prochaines ceintures —, et pour chaque domaine ce que
  # chacune y mettrait. Mode d'entrée : les ceintures des plans, s'il y en a.
  def new_belt_sheet
    @student = authorize Student.includes(classroom: :grade).find(params[:id]), :show?
    @domains = @student.classroom.grade.domains.sort_by(&:position)
    @apercu = BeltSheet.apercu(@student, @domains)
    @mode = @apercu.values.any? { |a| a[:en_cours].any? } ? "en_cours" : "resultats"
  end

  # Cloner une fiche de ceinture : les élèves du même niveau, classe par classe.
  def clone_belt_sheet
    @belt_sheet = authorize BeltSheet.find(params[:id]), :clone?
    @candidates = @belt_sheet.clone_candidates(current_user).group_by(&:classroom)
  end

  private

  def new_work_plan_for(student)
    monday = Date.current.at_beginning_of_week
    WorkPlan.new(
      student: student,
      grade: student.classroom.grade,
      name: "Plan de travail - #{student.first_name.capitalize}",
      start_date: monday,
      end_date: monday + 4
    )
  end
end
