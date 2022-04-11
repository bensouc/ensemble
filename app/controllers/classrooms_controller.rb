class ClassroomsController < ApplicationController
  def index
    @classrooms = Classroom.where(user_id: current_user)
    @students_list = []
    @classrooms.each do |classroom|
      @students_list << [classroom, classroom.student_list]
    end
  end
end
