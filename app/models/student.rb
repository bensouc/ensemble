class Student < ApplicationRecord
  belongs_to :classroom

  has_many :work_plans

  validates :first_name, presence: true
end
