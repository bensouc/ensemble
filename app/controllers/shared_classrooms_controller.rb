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
        classroom: classroom
      )
      next if shared_classroom.save

      redirect_to classrooms_path,
                  alert: "Un partage a échoué, cette classe est déjà partagée avec #{teacher.first_name.capitalize}"
      return
    end
    message = current_user.first_name + " a partagé avec vous la classe " + classroom.name.to_s
    teachers.each do |teacher|
      SharingMessages.send_ensemble_message_to_user(teacher, message)
    end
    redirect_to classrooms_path, notice: "Partage réussi"
  end

  # Défaire un partage : le collègue quitte la classe, ou le propriétaire la
  # reprend. La classe et ses élèves ne sont pas touchés.
  #
  # On autorise le PARTAGE et non la classe : sur la classe, n'importe quel
  # collègue passait, et pouvait donc retirer le partage d'un autre collègue.
  def destroy
    shared_classroom = SharedClassroom.find(params[:id])
    authorize shared_classroom
    shared_classroom.destroy
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
