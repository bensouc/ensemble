# frozen_string_literal: true

class SharedClassroomsController < ApplicationController
  def create
    @teachers_ids = set_shared_classroom_teacher_params.reject(&:blank?)
    classroom = Classroom.find(set_classroom)
    authorize SharedClassroom.new(classroom: classroom)
    teachers = @teachers_ids.map { |t| User.find(t) }
    # Chaque destinataire est vérifié avant le premier partage : un refus au
    # milieu laisserait la classe partagée à moitié.
    shared_classrooms = teachers.map { |teacher| authorize SharedClassroom.new(user: teacher, classroom:) }
    shared_classrooms.each do |shared_classroom|
      next if shared_classroom.save

      redirect_to classrooms_path,
                  alert: "Un partage a échoué, cette classe est déjà partagée avec #{shared_classroom.user.short_name}"
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
