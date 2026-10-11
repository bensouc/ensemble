# frozen_string_literal: true

# Les blocs d'une fiche de ceinture : un domaine à une couleur de ceinture.
# L'ajouter le garnit des compétences que l'élève n'a pas encore validées.
class BeltSheetDomainsController < ApplicationController
  def new
    @belt_sheet = BeltSheet.find(params[:belt_sheet_id])
    authorize @belt_sheet, :update?
    @domains = @belt_sheet.grade.domains.sort_by(&:position)
    @special = @domains.any?(&:special?)
  end

  def create
    @belt_sheet = BeltSheet.find(params[:belt_sheet_id])
    authorize @belt_sheet, :update?
    flash.now[:notice] = ajouter(domaine_choisi, domain_params[:level].to_i.clamp(1, Belt::BELT_COLORS.size))
    respond_with_sheet
  end

  def destroy
    bloc = BeltSheetDomain.find(params[:id])
    @belt_sheet = bloc.belt_sheet
    authorize @belt_sheet, :update?
    bloc.destroy
    flash.now[:notice] = t("fiches_ceinture.bloc_retire")
    respond_with_sheet
  end

  private

  # Le domaine vient du formulaire : un domaine du niveau de l'élève, et de son
  # école — sans quoi la fiche se garnissait des compétences d'une autre.
  def domaine_choisi
    authorize @belt_sheet.grade.domains.find(domain_params[:domain_id]), :show?
  end

  def ajouter(domain, level)
    noms = { domaine: domain.name, couleur: Belt::BELT_COLORS[level - 1], eleve: @belt_sheet.student.first_name }
    if @belt_sheet.belt_sheet_domains.exists?(domain:, level:)
      t("fiches_ceinture.bloc_deja_la", **noms)
    elsif @belt_sheet.add_domain!(domain, level)
      t("fiches_ceinture.bloc_ajoute", **noms)
    else
      t("fiches_ceinture.tout_valide", **noms)
    end
  end

  # Toute la liste est re-rendue : un bloc se range à la place de son domaine,
  # pas à la fin.
  def respond_with_sheet
    @belt_sheet.reload
    respond_to do |format|
      format.html { redirect_to belt_sheet_path(@belt_sheet) }
      format.turbo_stream { render "belt_sheet_domains/refresh" }
    end
  end

  def domain_params
    params.expect(belt_sheet_domain: [:domain_id, :level])
  end
end
