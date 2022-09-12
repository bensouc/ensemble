class Mobile::WorkPlansController < ApplicationController
  def index
    @my_classrooms = Classroom.where(user: current_user)
    @my_work_plans = WorkPlan.where(user: current_user).order(created_at: :DESC) # .sort_by(&:student)
    @my_work_plans_unassigned = @my_work_plans.where(student: nil)
    @my_work_plans = @my_work_plans.where.not(student: nil).sort_by(&:student)
  end
end
