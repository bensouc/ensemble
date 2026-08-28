class Mobile::StudentsController < ApplicationController
  layout "mobile"
  before_action :set_student, only: [:show]

  # La route est imbriquée sous la classe : on liste les élèves de CETTE classe,
  # pas tous ceux qu'on peut voir. `@classroom` manquait, alors que le gabarit
  # s'en sert pour construire les liens vers chaque élève.
  def index
    @classroom = Classroom.find(params[:classroom_id])
    authorize @classroom, :show?
    @students = policy_scope(@classroom.students)
  end

  def show
    authorize @student
    @belts = Belt.completed.where(student: @student)
    @domains = @student.domains.sort_by(&:position)
    # binding.pry
  end

  private

  def set_student
    @student = Student.find(params[:id])
    @classroom = @student.classroom
  end
end
