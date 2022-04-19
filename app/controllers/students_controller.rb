class StudentsController < ApplicationController
  def new
    @classroom = Classroom.find(classroom_params_id)
    @student = Student.new(classroom_id: @classroom.id)
  end

  def create
    student = {
      first_name: params_student[:first_name],
      classroom_id: params_student[:classroom].to_i,

    }
    @student = Student.create!(student)
    redirect_to classrooms_path
  end

  def destroy
    @student = Student.find(params[:id])
    @student.destroy
    redirect_to classrooms_path
  end

  private

  def params_student
    params.require(:student)
  end

  def classroom_params_id
    params.require(:classroom_id)
  end
end
