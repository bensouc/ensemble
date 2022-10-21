class SharedClassroomsController < ApplicationController
  def create
    @teachers_ids = set_shared_classroom_teacher_params.reject(&:blank?)
    classroom = Classroom.find(set_classroom)
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
    redirect_to classrooms_path, notice: "Partage réussi"
  end

  def destroy
    shared_classroom = SharedClassroom.find(params[:id])
    # get original classroom
    classroom = shared_classroom.classroom
    shared_classroom.destroy
    # if sharedclassrooms.count == 0 => classroom.shared = false
    classroom.shared = false if classroom.shared_classrooms.count
    redirect_to classrooms_path
  end

  private

  def set_shared_classroom_teacher_params
    # params.require(:shared_classroom).require(:teachers)
    params.require(params.require(:classroom_id)).require(:teachers)
  end

  def set_classroom
    params.require(:classroom_id).to_i
  end
end
