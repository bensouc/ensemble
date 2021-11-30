class Modiffieldchallenge < ActiveRecord::Migration[6.0]
  def change
    change_column_default :challenges, :shared, from: nil, to: true
  end
end
