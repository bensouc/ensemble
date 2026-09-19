class ResultsController < ApplicationController
  def validate
    @result = Refult.find(params[:id])
    authorize @result
    @result.validate!
    manage_belt_and_render
  end

  def create
    @result = Result.find_or_create_by(student_id: result_params[:student_id], skill_id: result_params[:skill_id])
    authorize @result
    @result.update!(result_params.merge(origin: Result::DIRECT))
    manage_belt_and_render
  end

  # Le recalcul est explicite : `Result` ne prévient ses ceintures que sur
  # `:create` et `:update`, et une suppression laissait donc la ceinture validée
  # alors qu'une de ses compétences ne l'était plus.
  def destroy
    @result = Result.find(params[:id])
    authorize @result
    @result.destroy
    @result.belt_update_by_domain_and_level
    manage_belt_and_render
  end

  private

  def manage_belt_and_render
    # @result.belt_update_by_domain_and_level
    respond_to do |format|
      # format.html { redirect_to results_path }
      format.turbo_stream
    end
  end

  def result_params
    params.require(:result).permit(:student_id, :skill_id, :status, :kind)
  end
end
