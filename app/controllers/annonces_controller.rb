# frozen_string_literal: true

# Les deux boutons d'une annonce du tableau de bord. Le compte n'agit que sur
# lui-même : pas de policy à consulter. Pendant une personnification, rien n'est
# écrit sur le compte de la personne (le tableau de bord n'y montre d'ailleurs
# aucune annonce).
class AnnoncesController < ApplicationController
  before_action :skip_authorization
  before_action :trouver_annonce

  # « Plus tard » : de retour le lendemain.
  def reporter
    unless impersonating?
      reportees = current_user.annonces_reportees.merge(@annonce.id => Date.current.iso8601)
      current_user.update!(annonces_reportees: reportees)
    end
    redirect_to dashboard_path, status: :see_other
  end

  # « Ne plus afficher » : pour de bon.
  def masquer
    current_user.update!(annonces_masquees: current_user.annonces_masquees | [@annonce.id]) unless impersonating?
    redirect_to dashboard_path, status: :see_other
  end

  private

  def trouver_annonce
    @annonce = Annonce.trouver(params[:id])
    head :not_found unless @annonce
  end
end
