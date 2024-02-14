# frozen_string_literal: true

class DomainsController < ApplicationController
  skip_after_action :verify_policy_scoped, only: [:index]
  before_action :set_domain, only: [:edit, :destroy]

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
  end

  def create
    @grade = Grade.find(params[:grade_id])
    @domain = Domain.new(set_params)
    authorize(@domain)
    @domain.save
    respond_to do |format|
      format.html { redirect_to grade_domains_path(@grade), notice: "Domaine Sauvegardé" }
      format.turbo_stream
    end
  end

  def destroy
    authorize @domain
    if @domain.destroy
      respond_to do |format|
        format.html { redirect_to grade_domains_path(@grade), notice: "Domaine Supprimé" }
        format.turbo_stream
      end
    else
      redirect_to grade_domains_path(@grade), notice: "La suppression du domaine a échoué"
    end
  end

  private

  def set_domain
    @domain = Domain.find(params[:id])
  end

  def set_params
    params.require(:domain).permit(:grade_id, :name)
  end
end
