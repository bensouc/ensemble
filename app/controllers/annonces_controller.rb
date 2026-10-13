# frozen_string_literal: true

# « Ne plus afficher » une annonce du tableau de bord. Le compte n'agit que sur
# lui-même : pas de policy à consulter.
class AnnoncesController < ApplicationController
  def masquer
    skip_authorization
    annonce = Annonce.trouver(params[:id])
    return head :not_found unless annonce

    current_user.update!(annonces_masquees: (current_user.annonces_masquees | [annonce.id])) unless impersonating?
    redirect_to dashboard_path, status: :see_other
  end
end
