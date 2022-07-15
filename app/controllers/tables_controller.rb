# frozen_string_literal: true

class TablesController < ApplicationController
  def show
    @table = Table.find params[:id]
    render json: {
      sgid: @table.attachable_sgid,
      content: render_to_string(partial: "tables/editor", locals: { table: @table }, formats: [:html])
    }
  end

  def create
    @table = Table.create
    render json: {
      sgid: @table.attachable_sgid,
      content: render_to_string(partial: "tables/editor", locals: { table: @table }, formats: [:html])
    }
  end

  def update
    @table = ActionText::Attachable.from_attachable_sgid params[:id]

    case params["method"]
    when "addRow"
      @table.rows += 1
    when "addColumn"
      @table.columns += 1
    when "updateCell"
      @table.data[params["cell"]] = params["value"]
    end
    @table.save
    render json: {
      sgid: @table.attachable_sgid,
      content: render_to_string(partial: "tables/editor", locals: { table: @table }, formats: [:html])
    }
  end
end
