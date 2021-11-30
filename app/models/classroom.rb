class Classroom < ApplicationRecord
  belongs_to :user

  has_many :students

  validates :grade, presence: true
end
