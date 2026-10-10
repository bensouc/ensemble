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

  def display_skills_modal
    @student = authorize Student.find(params[:student_id]), :show?
    @domain = Domain.find(params[:id])
    @skills = @domain.skills
    # `skill:` et non `skills:` : Rails 7.2 ne rattrape plus le pluriel d'une
    # association `belongs_to`. La requête cherchait une colonne
    # `results.skills` et la modale tombait en 500.
    @results = Result.completed.includes(:skill).where(
      skill: @skills,
      student: @student
    ).sort_by { |result| [result.skill.symbol, result.skill.name] }
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
