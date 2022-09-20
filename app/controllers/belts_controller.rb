# frozen_string_literal: true

class BeltsController < ApplicationController
  def create
    @belt = Belt.create(new_belt_params)
    @belt.completed = true
    @belt.student = Student.find(params[:student_id])
    @belt.save
  
redirect_to student_path(@belt.student)
  end

  private

  def new_belt_params
  params.require(:belt).permit( :grade, :domain, :level, :grade)
  end
end
