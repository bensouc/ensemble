# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  before_validation :set_defaults

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  validates :first_name, presence: true
  validates :last_name, presence: true

  # belongs_to :school
  has_one :school_role # Un utilisateur a une seule school_role
  has_one :school, through: :school_role # Un utilisateur appartient à une seule école à travers schoolRole

  has_many :classrooms, dependent: :destroy
  has_many :work_plans, dependent: :destroy
  has_many :shared_work_plans, class_name: "WorkPlan", foreign_key: "shared_user_id",
                               dependent: nil
  has_many :shared_classrooms, dependent: :destroy
  has_many :user_shared_classrooms, through: :shared_classrooms, source: "classroom"
  has_many :students, through: :classrooms, dependent: :destroy
  has_many :challenges, dependent: nil

  has_one :subscription, dependent: :destroy
  has_one_attached :avatar


  def classroom_grades
    # return all current user classroom Grades
    classrooms.map { |classroom| classroom.grade }
  end

  def classroom?
    # return true if user has a classroom
    !classrooms.empty?
  end

  def collegues
    school.users.reject { |y| y == self }
  end

  private

  def set_defaults
    self.school = School.where(name: "Ensemble") if school.blank?
  end
end
