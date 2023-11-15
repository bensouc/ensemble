class GradesController < ApplicationController
  before_action :set_grade, only: [:show]

  def index
    @grades = policy_scope(Grade)
  end

  private

  def set_grade
    @grade = Grade.find(params[:id])
  end
end
