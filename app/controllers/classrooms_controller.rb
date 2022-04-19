class ClassroomsController < ApplicationController
  def index
    @classrooms = Classroom.where(user_id: current_user)
    @students_list = []
    @classrooms.each do |classroom|
      @students_list << [classroom, classroom.student_list]
    end
  end

  def create
    @classroom = Classroom.create(set_classroom_params)
    @classroom.user=current_user
    @classroom.save!

    redirect_to classrooms_path
  end

  private

  def set_classroom_params
    raise
  end

end
