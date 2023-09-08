# frozen_string_literal: true

class BeltsController < ApplicationController
  before_action :set_belt, only: [:edit, :update, :destroy]
  def edit

    authorize @belt
    @skills = @belt.all_skills(current_user)
  end

  def create
    skip_authorization
    args = new_belt_params
    args[:student_id] = params[:student_id]
    @belt = Belt.find_or_create_by(args)
    @belt.completed = true
    # @belt.student = Student.find(params[:student_id])
    @belt.validated_date = DateTime.now
    @belt.save

    redirect_to student_path(@belt.student)
  end

  def update

    # binding.pry
    @belt.validated_date = new_belt_params[:validated_date]
    if @belt.save
      redirect_to student_path(@belt.student)
    else
      redirect_to :edit
    end
  end

  def destroy

    @student = @belt.student
    @belt.destroy
    redirect_to student_path(@student)
  end

  private

  def set_belt
    @belt = Belt.find(params[:id])
    authorize @belt
  end

  def new_belt_params
    params.require(:belt).permit(:grade, :domain, :level, :grade, :validated_date)
  end
end
