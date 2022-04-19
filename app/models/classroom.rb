class Classroom < ApplicationRecord
  GRADE = ['CP', 'CE1', 'CE2', 'CM1', 'CM2']
  belongs_to :user

  has_many :students, dependent: :destroy

  validates :grade, presence: true

  def student_list
    Student.where(classroom_id: self.id)
  end
end
