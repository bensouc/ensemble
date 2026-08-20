# frozen_string_literal: true

class ModalsController < ApplicationController
  def auto_gen
    @student = Student.includes(:classroom).find(params[:id])
    skip_authorization
    @domains = @student.classroom.grade.domains.sort_by(&:position)
  end

  # Création rapide d'un plan de travail depuis la liste des plans de travail :
  # une seule modale, deux issues — un plan vierge ou un plan auto-généré sur le
  # niveau de l'élève. Les deux réutilisent les mécaniques existantes
  # (`work_plans#create` et `work_plans#auto_new_wp`).
  def new_work_plan
    @student = Student.includes(classroom: :grade).find(params[:id])
    skip_authorization
    return head :forbidden unless current_user.all_students.include?(@student)

    @work_plan = new_work_plan_for(@student)
  end

  def display_skills_modal
    @student = Student.find(params[:student_id])
    @domain = Domain.find(params[:id])
    @skills = @domain.skills
    @results = Result.completed.where(
      skills: @skills,
      student: @student
    ).sort_by { |result| [result.skill.symbol, result.skill.name] }
    # binding.pry
    skip_authorization
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
