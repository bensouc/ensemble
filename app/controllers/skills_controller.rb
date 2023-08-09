# frozen_string_literal: true

class SkillsController < ApplicationController
  def index
    @grades = current_user.classroom_grades
    query = params[:grade]
    @grade =  if query.nil?
                @grades.first  # gérer la query later ici
              else
                query
              end
    @skills = Skill.for_school(current_user.school)
    @are_special_domains = current_user.school.id == 1
    @skills = @skills.select { |skill| skill.grade == @grade}
    # for production => "A fournier == "
    # @are_special_domains = current_user.school.id == 1

  end

  # private

end
