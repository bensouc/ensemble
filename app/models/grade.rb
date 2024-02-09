class Grade < ApplicationRecord
  belongs_to :school
  has_many :classrooms, dependent: :destroy
  has_many :work_plans, dependent: :destroy
  # has_many :domains, dependent: :destroy
  has_many :belts, dependent: :destroy
  has_many :skills, dependent: :destroy
  has_many :students, through: :classrooms, source: "students", dependent: :destroy

  validates :grade_level, presence: true, inclusion: Classroom::GRADE
  validates :name,  presence: true,
                    uniqueness: { message: "Le nom de cet niveau éxiste déja", scope: :school },
                    length: { maximum: 15, message: "est trop long (pas plus de 15 caractères)"}

  before_validation :set_default

  def self.find_grade_by_school_and_grade_level(school, grade_level)
    Grade.find_by(grade_level:, school:)
  end

  private

  def set_default
    self.name = grade_level if name.nil? || name == ""
  end
end
