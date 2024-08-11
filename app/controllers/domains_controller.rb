# frozen_string_literal: true

class DomainsController < ApplicationController
  skip_after_action :verify_policy_scoped, only: [:index]
  before_action :set_domain, only: [:show,:edit, :destroy, :update, :move]

  def index
    @grade = Grade.find(params[:grade_id])
    @domains = @grade.domains
  end

  def new
    @grade = Grade.find(params[:grade_id])
    @domain = Domain.new(grade: @grade)

    authorize(@domain)
  end

  def show
    authorize(@domain)
  end

  def edit
    authorize(@domain)
    @grade = @domain.grade
  end

  def create
    @domain = Domain.new(set_params)
    @grade = @domain.grade
    authorize(@domain)
    @domain.save
    respond_to do |format|
      format.html { redirect_to grade_domains_path(@grade), notice: "Domaine Sauvegardé" }
      format.turbo_stream
    end
  end

  def update
    authorize @domain
    if @domain.update(set_params)
      respond_to do |format|
        format.html { redirect_to domain_path(@domain), notice: "Domaine Sauvegardé" }
        format.turbo_stream
      end
    else
      redirect_to redirect_to grade_domains_path(@domain.grade), notice: "Sauvegarde échouée "
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
      respond_to do |format|
        format.html { redirect_to grade_domains_path(@grade), notice: "La suppression du domaine a échoué" }
        format.turbo_stream { render turbo_stream:
                                turbo_stream.replace(@domain,
                                  partial: "domains/domain",
                                  locals: { domain: @domain })
                            }
      end
    end
  end

  def move
    authorize @domain
    # binding.pry
    @domain.insert_at(params[:position].to_i)
  end

  private

  def set_domain
    @domain = Domain.find(params[:id])
  end

  def set_params
    params.require(:domain).permit(:grade_id, :name)
  end

  # def set_position
  #   params.require
  # end
end
