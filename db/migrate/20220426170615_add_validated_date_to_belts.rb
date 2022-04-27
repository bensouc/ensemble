class AddValidatedDateToBelts < ActiveRecord::Migration[6.0]
  def change
    add_column :belts, :validated_date, :date, default: Time.now
  end
end
