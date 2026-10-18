class Mobile::ClassroomsController < ApplicationController
  layout "mobile"
  before_action :set_classroom, only: [:show]

  # Les siennes d'abord, puis celles qu'on lui partage, chacune par niveau —
  # l'ordre du bureau. Les classes partagées manquaient : la fiche d'un de leurs
  # élèves s'ouvrait, mais rien n'y menait.
  def index
    partagees = policy_scope(SharedClassroom).includes(classroom: :grade).map(&:classroom)
    @classrooms = Classroom.par_niveau(policy_scope(Classroom).includes(:grade)) + Classroom.par_niveau(partagees)
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
