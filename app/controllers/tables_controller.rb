# frozen_string_literal: true

class TablesController < ApplicationController
  before_action :get_table_from_sgid, only: [:update]

  def show
    skip_authorization
    @table = Table.find params[:id]
    render json: attachment_json(@table)
  end

  def create
    skip_authorization
    @table = Table.create(rows: 3, columns: 3)
    render json: attachment_json(@table)
  end

  def update
    skip_authorization

    case params["method"]
    # --- Chemin utilisé par l'éditeur actuel : un seul aller-retour pour tout l'état.
    when "replace"
      @table.replace!(table_params)
    # --- Ancienne API : conservée pour les bundles JS encore en cache navigateur
    #     pendant la fenêtre de déploiement. L'éditeur actuel n'envoie que
    #     "replace", toutes ses opérations de structure étant locales au DOM.
    when "addRow"        then @table.insert_row!(@table.rows)
    when "addColumn"     then @table.insert_column!(@table.columns)
    when "removeRow"     then @table.delete_row!(@table.rows - 1)
    when "removeColumn"  then @table.delete_column!(@table.columns - 1)
    when "updateCell"    then @table.write_cell!(params["cell"], params["value"])
    else
      return render json: { error: "unknown method" }, status: :unprocessable_entity
    end

    render json: attachment_json(@table, snapshot: params["snapshot"].present?)
  end

  private

  def table_params
    params.require(:table)
          .permit(:rows, :columns, :header_row, col_aligns: [], data: {}, cell_styles: {}, cell_colors: {})
          .to_h
  end

  # `content` n'est construit qu'à la demande : le client ne s'en sert qu'à la
  # sortie d'un tableau et avant envoi du formulaire, alors que le partial coûte
  # deux appels de helper par cellule. L'enregistrement courant — frappe
  # debouncée, déplacement de cellule — n'en a aucun usage.
  def attachment_json(table, snapshot: true)
    payload = {
      sgid: table.attachable_sgid,
      contentType: "application/octet-stream"
    }
    return payload unless snapshot

    payload.merge(
      # Instantané volontairement rendu avec le partial d'ÉDITION, pas celui
      # d'affichage : ActionText re-rend le partial depuis l'enregistrement pour
      # l'affichage, mais Trix, lui, reconstruit la pièce jointe à partir de ce
      # `content` quand son cache de vues est invalidé. S'il contenait le rendu
      # lecture seule, un re-rendu ferait disparaître la toolbar du tableau.
      # Pas d'autres clés ici : `insertTable` passe cette réponse telle quelle à
      # `new Trix.Attachment(...)`, donc tout ajout deviendrait un attribut de la
      # pièce jointe et finirait sérialisé dans le corps du rich text.
      content: render_to_string(partial: "tables/editor", locals: { table: table }, formats: [:html])
    )
  end

  def get_table_from_sgid
    @table = ActionText::Attachable.from_attachable_sgid params[:id]
  rescue ActiveRecord::RecordNotFound
    skip_authorization
    render json: { error: "table not found" }, status: :not_found
  end
end
