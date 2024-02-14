# frozen_string_literal: true

class DomainsController < ApplicationController
  skip_after_action :verify_policy_scoped, only: [:index]

  def index
    @grade = Grade.find(params[:grade_id])
    @domains = @grade.domains
  end

  def new
    @grade = Grade.find(params[:grade_id])
    @domain = Domain.new(grade: @grade)

    authorize(@domain)
  end

  def edit
    @domain = Domain.find(params[:id])
  end

  def create
    @grade = Grade.find(params[:grade_id])
    @domain = Domain.new(set_domain)
    authorize(@domain)
    @domain.save!
    respond_to do |format|
      format.html { redirect_to grade_domains_path(@grade, @domain), notice: "Domaine Sauvegardé" }
      format.turbo_stream
    end
  end

  private

  def set_domain
    params.require(:domain).permit(:grade_id, :name)
  end
end
