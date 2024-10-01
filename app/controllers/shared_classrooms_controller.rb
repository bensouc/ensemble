# frozen_string_literal: true
class SharedClassroomsController < ApplicationController
  def create
    @teachers_ids = set_shared_classroom_teacher_params.reject(&:blank?)
    classroom = Classroom.find(set_classroom)
    authorize SharedClassroom.new(classroom: classroom)
    teachers = @teachers_ids.map { |t| User.find(t) }
    teachers.each do |teacher|
      shared_classroom = SharedClassroom.new(
        user_id: teacher.id,
        classroom: classroom,
      )
      next if shared_classroom.save

      redirect_to classrooms_path,
                  alert: "Un partage a échoué, cette classe est déjà partagée avec #{teacher.first_name.capitalize}"
      return
    end
    classroom.shared = true
    classroom.save
    message = current_user.first_name + " a partagé avec vous la classe " + classroom.name.to_s
    teachers.each do |teacher|
      SharingMessages.send_ensemble_message_to_user(teacher, message)
    end
    redirect_to classrooms_path, notice: "Partage réussi"
  end

  def destroy
    shared_classroom = SharedClassroom.find(params[:id])
    # get original classroom
    classroom = shared_classroom.classroom
    authorize classroom
    shared_classroom.destroy
    # if sharedclassrooms.count == 0 => classroom.shared = false
    classroom.shared = false if classroom.shared_classrooms.count
    redirect_to classrooms_path
  end

  private

  def set_shared_classroom_teacher_params
    # params.require(:shared_classroom).require(:teachers)
    # raise
    params.require(params.require(:classroom_id)).require(:teachers)
  end

  def set_classroom
    params.require(:classroom_id).to_i
  end
end
