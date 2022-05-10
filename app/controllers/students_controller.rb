class StudentsController < ApplicationController
  def new
    @classroom = Classroom.find(classroom_params_id)
    @student = Student.new(classroom_id: @classroom.id)
  end

  def show
    @student = Student.find(params[:id])
    @belt = Belt::BELT_COLORS
    @all_skills = []
    @student_grade = @student.classroom.grade
    Skill.where(grade: @student_grade).each do |skill|
      @all_skills << {
        skill: skill,
        last_wps: WorkPlanSkill.last_wps(@student.id, skill.id)
      }
    end
    #cleaning of the useless lastwps (eg: special domain, remove the amount)
    
    @belts = Belt.where(student: @student, grade: @student_grade)
  end

  def create
    student = {
      first_name: params_student[:first_name],
      classroom_id: params_student[:classroom].to_i,

    }
    @student = Student.create!(student)
    redirect_to classrooms_path
  end

  def destroy
    @student = Student.find(params[:id])
    @student.destroy
    redirect_to classrooms_path
  end

  private

  def params_student
    params.require(:student)
  end

  def classroom_params_id
    params.require(:classroom_id)
  end
end
