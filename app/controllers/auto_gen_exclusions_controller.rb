# frozen_string_literal: true

# Sortir un domaine de la génération automatique, ou l'y remettre. La préférence
# n'engage que le professeur connecté : les domaines sont ceux de l'école, et un
# collègue qui génère ses plans n'en voit rien.
class AutoGenExclusionsController < ApplicationController
  before_action :set_domain

  def create
    current_user.auto_gen_exclusions.find_or_create_by!(domain: @domain)
    render_domain
  end

  def destroy
    current_user.auto_gen_exclusions.where(domain: @domain).delete_all
    render_domain
  end

  private

  # Le droit de régler un domaine est celui de le voir : un domaine de son école.
  def set_domain
    @domain = authorize Domain.find(params[:domain_id]), :show?
  end

  def render_domain
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(@domain, partial: "domains/domain", locals: { domain: @domain })
      end
      format.html { redirect_to grade_domains_path(@domain.grade) }
    end
  end
end
