# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  before_validation :set_defaults

  # before DESTROY
  # REVERSE CHALLENGE TO sCHOOL SUPERuser IF no super user then teacher on same grade else first teacher of scchool
  before_destroy :transmit_all_challenges

  # associations
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # belongs_to :school
  has_one :school_role, dependent: :destroy # Un utilisateur a une seule school_role
  has_one :school, through: :school_role # Un utilisateur appartient à une seule école à travers schoolRole
  has_one :subscription, through: :school
  has_many :classrooms, dependent: :destroy
  has_many :work_plans, dependent: :destroy
  has_many :shared_work_plans, class_name: "WorkPlan", foreign_key: "shared_user_id",
                               dependent: nil
  has_many :shared_classrooms, dependent: :destroy
  has_many :user_shared_classrooms, through: :shared_classrooms, source: "classroom"
  has_many :students, through: :classrooms, dependent: :destroy
  has_many :challenges, dependent: nil

  # has_one :subscription, dependent: :destroy
  has_one_attached :avatar
  # Validations
  validates :first_name, presence: true
  validates :last_name, presence: true

  # Methods
  def admin?
    admin
  end

  def demo?
    demo
  end

  def super_teacher?
    school_role.super_teacher == true
  end

  def classroom_grades
    # return all current user classroom Grades
    grades = classrooms.map { |classroom| classroom.grade }
    shared_classrooms.each { |shared_classroom| grades << shared_classroom.classroom.grade }
    grades.uniq.sort
  end

  def classroom?
    # return true if user has a classroom
    !classrooms.empty? || !shared_classrooms.empty?
  end

  def collegues
    school.users.reject { |y| y == self }
  end

  def all_students
    shared_students = []
    unless shared_classrooms.empty?
      shared_classrooms.each do |shared_classroom|
        shared_students += shared_classroom.classroom.students
      end
    end
    (students.includes([:classroom]) + shared_students).sort_by(&:classroom)
  end

  def all_classroom_workplans
    work_plans = []
    unless classrooms.empty?
      classrooms.each do |classroom|
        classroom.students.each do |student|
          work_plans += WorkPlan.where(student:, special_wps: false)
        end
      end
    end
    work_plans
  end

  def all_shared_classroom_workplans
    work_plans = []
    unless shared_classrooms.empty? # get all workplans shared with current user
      shared_classrooms.each do |shared_classroom|
        shared_classroom.classroom.students.each do |student|
          work_plans += WorkPlan.where(student:, special_wps: false)
        end # get all workplans of shared classrooms
      end
    end
    work_plans
  end

  private

  def set_defaults
    SchoolRole.create!(user: self, school: School.where(name: "Ensemble").first) if school_role.nil?
  end

  def transmit_all_challenges
    # get new user <= superteacher
    new_user = school.super_teachers.first
    # iterate on challenge and update user
    challenges.each { |challenge| challenge.update(user: new_user) }
  end
end
