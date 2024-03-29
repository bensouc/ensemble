class ModalsController < ApplicationController
  def auto_gen
    @student = Student.includes(:classroom).find(params[:id])
    skip_authorization
    @domains = @student.classroom.grade.domains
  end
end
