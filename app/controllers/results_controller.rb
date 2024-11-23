class ResultsController < ApplicationController
  def validate
    @result = Refult.find(params[:id])
    authorize @result

    @result.validate!
    @result.belt_update_by_domain_and_level
    respond_to do |format|
      format.html { redirect_to classroom_results_path(@result.student.classroom) }
      format.turbo_stream
    end
  end
  def create
    @result = Result.find_or_create_by(student_id: result_params[:student_id], skill_id: result_params[:skill_id])
    authorize @result
    @result.update!(result_params)
    @result.belt_update_by_domain_and_level
    respond_to do |format|
    format.html { redirect_to classroom_results_path(@result.student.classroom) }
    format.turbo_stream
  end
end

  private

  def result_params
    params.require(:result).permit(:student_id, :skill_id, :status, :kind)
  end

end
