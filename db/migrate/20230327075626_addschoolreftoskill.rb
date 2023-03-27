class Addschoolreftoskill < ActiveRecord::Migration[6.0]
  def change
    add_reference :skills, :school, foreign_key: true
  end
end
