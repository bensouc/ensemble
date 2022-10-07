# frozen_string_literal: true

class ClassroomsController < ApplicationController
  def index
    @classrooms = current_user.classrooms
    @students_list = []
    @school_teachers = User.where(school: current_user.school).reject { |y| y == current_user }
    @classrooms.each do |classroom|
      @students_list << [classroom, classroom.students]
    end
  end

  def create
    @classroom = Classroom.create(set_classroom_params)
    @classroom.user = current_user
    @classroom.name = nil if @classroom.name == ""

    @classroom.save!

    redirect_to classrooms_path
  end

  def destroy
    @classroom = Classroom.find(params[:id])
    @classroom.destroy
    redirect_to classrooms_path
  end

  private

  def set_classroom_params
    params.require(:classroom).permit(:grade, :name)
  end
end
