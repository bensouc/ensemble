# frozen_string_literal: true

class BeltsController < ApplicationController
  def edit
    @belt = Belt.find(params[:id])
    @skills = @belt.all_skills
  end

  def create
    @belt = Belt.create(new_belt_params)
    @belt.completed = true
    @belt.student = Student.find(params[:student_id])
    @belt.validated_date = DateTime.now
    @belt.save

    redirect_to student_path(@belt.student)
  end

  def update
    @belt = Belt.find(params[:id])
    @belt.validated_date = new_belt_params[:validated_date]
    if @belt.save
      redirect_to student_path(@belt.student)
    else
      redirect_to :edit
    end
  end

  def destroy
    belt = Belt.find(params[:id])
    @student = belt.student
    belt.destroy
    redirect_to student_path(@student)
  end

  private

  def new_belt_params
    params.require(:belt).permit(:grade, :domain, :level, :grade, :validated_date)
  end
end
