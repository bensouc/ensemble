class Classroom < ApplicationRecord
  GRADE = ['CP', 'CE1', 'CE2', 'CM1', 'CM2']
  belongs_to :user

  has_many :students

  validates :grade, presence: true
end
