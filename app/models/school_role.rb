class SchoolRole < ApplicationRecord
  belongs_to :user
  belongs_to :school

  def super_teacher?
    super_teacher
  end
end
