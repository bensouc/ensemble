class Mobile::ClassroomsController < ApplicationController
  layout "mobile"
  before_action :set_classroom, only: [:show]

  def index
    @classrooms = policy_scope(Classroom)
  end

  def show
    authorize @classroom
  end

  private

  def set_classroom
    @classroom = Classroom.find(params[:id])
    @students = @classroom.students
  end
end
