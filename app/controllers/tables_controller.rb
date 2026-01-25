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
    @table = Table.create
    render json: attachment_json(@table)
  end

  def update
    skip_authorization
    case params["method"]
    when "addRow"
      @table.rows += 1
    when "addColumn"
      @table.columns += 1
    when "removeRow"
      if @table.rows > 1
        # Remove data for the last row
        last_row = @table.rows - 1
        (0...@table.columns).each do |c|
          @table.data.delete("#{last_row}-#{c}")
        end
        @table.rows -= 1
      end
    when "removeColumn"
      if @table.columns > 1
        # Remove data for the last column
        last_col = @table.columns - 1
        (0...@table.rows).each do |r|
          @table.data.delete("#{r}-#{last_col}")
        end
        @table.columns -= 1
      end
    when "updateCell"
      @table.data[params["cell"]] = params["value"]
    end
    @table.save
    render json: attachment_json(@table)
  end

  private

  def attachment_json(table)
    {
      sgid: table.attachable_sgid,
      contentType: "application/octet-stream",
      content: render_to_string(partial: "tables/editor", locals: { table: table }, formats: [:html])
    }
  end

  def get_table_from_sgid
    @table = ActionText::Attachable.from_attachable_sgid params[:id]
  end
end
