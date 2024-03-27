class AddPositionToDomain < ActiveRecord::Migration[7.0]
  def change
    add_column :domains, :position, :integer
    Grade.all.each do |grade|
      grade.domains.order(:updated_at).each.with_index(1) do |domain, index|
        domain.update_column :position, index
        end
    end
  end
end
