class ModalsController < ApplicationController
  def auto_gen
    @student = Student.includes(:classroom).find(params[:id])
    skip_authorization
    @domains = @student.classroom.grade.domains.sort_by(&:position)
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
end
