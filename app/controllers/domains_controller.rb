# frozen_string_literal: true

class DomainsController < ApplicationController
  skip_after_action :verify_policy_scoped, only: [:index]
  before_action :set_domain, only: [:show, :edit, :destroy, :update, :move]

  def index
    @grade = Grade.find(params[:grade_id])
    @domains = @grade.domains
  end

  def show
    authorize(@domain)
  end

  def new
    @grade = Grade.find(params[:grade_id])
    @domain = Domain.new(grade: @grade)

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
    # Sans ce garde-fou, `create.turbo_stream.erb` rendait `_domain` avec un
    # enregistrement sans `id` : `edit_domain_path(domain)` levait alors une
    # ActionView::Template::Error, et l'enseignant voyait un 500 au lieu du
    # message « ce nom de domaine existe déjà ».
    # `formats: [:html]` : le formulaire est toujours soumis depuis un turbo-frame,
    # c'est bien la page HTML que Turbo vient y découper — pas un flux.
    return render :new, status: :unprocessable_content, formats: [:html] unless @domain.save

    respond_to do |format|
      format.html { redirect_to grade_domains_path(@grade), notice: "Domaine Sauvegardé" }
      format.turbo_stream
    end
  end

  def update
    authorize @domain
    @grade = @domain.grade
    # Même règle qu'à la création : on réaffiche le formulaire avec l'erreur.
    # (L'ancienne branche d'échec appelait `redirect_to redirect_to`, ce qui
    # levait un AbstractController::DoubleRenderError.)
    return render :edit, status: :unprocessable_content, formats: [:html] unless @domain.update(set_params)

    respond_to do |format|
      format.html { redirect_to domain_path(@domain), notice: "Domaine Sauvegardé" }
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
      respond_to do |format|
        format.html { redirect_to grade_domains_path(@grade), notice: "La suppression du domaine a échoué" }
        format.turbo_stream do
          render turbo_stream:
                                turbo_stream.replace(@domain,
                                                     partial: "domains/domain",
                                                     locals: { domain: @domain })
        end
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
