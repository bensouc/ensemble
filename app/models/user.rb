# frozen_string_literal: true

class User < ApplicationRecord
  DEMO_CLASSROOM_LIMIT = 1
  DEMO_STUDENT_LIMIT = 5
  STUDENT_LIMIT = 25
  DISCOVERY_METHOD = ["Bouche-à-oreille", "Recherche sur Internet", "Réseaux sociaux", "Publicité en ligne", "Article de presse ou blog", "Événement ou conférence", "Autre"].freeze
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  before_validation :set_defaults

  # before DESTROY
  # REVERSE CHALLENGE TO sCHOOL SUPERuser IF no super user then teacher on same grade else first teacher of scchool
  before_destroy :transmit_all_challenges

  # associations
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :lastseenable

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
  # associations for conversations and messages
  has_many :user_conversations, dependent: :destroy
  has_many :conversations, through: :user_conversations
  has_many :messages, dependent: :destroy

  # has_one :subscription, dependent: :destroy
  has_one_attached :avatar

  # to be identified as reader
  acts_as_reader

  # Validations
  validates :first_name, presence: true
  validates :last_name, presence: true


  # Methods

  def avatar_url
    if admin?
      ActionController::Base.helpers.asset_path("icons/vroad_b_w.png")
    elsif avatar.attached?
      Cloudinary::Utils.cloudinary_url(avatar.key, width: 100, height: 100, crop: :fill)
    else
      "https://res.cloudinary.com/bensoucdev/image/upload/v1644250365/avatr_myemjn.png"
    end
  end

  def admin?
    admin == true
  end

  def demo?
    demo == true
  end

  def super_teacher?
    school_role.super_teacher == true
  end

  def classroom_grades
    # return all current user classroom Grades
    grades = classrooms.map(&:grade) # version propre de map { |classroom| classroom.grade }
    shared_classrooms.each { |shared_classroom| grades << shared_classroom.classroom.grade }
    grades.uniq.sort
  end

  def classroom?
    # return true if user has a classroom
    !classrooms.empty? || !shared_classrooms.empty?
  end

  def collegues
    school.users.reject { |user| user == self || user.admin? }
  end

  def collegues_with_avatars
    User.includes([avatar_attachment: :blob]).joins(:school_role)
      .where(school_roles: { school: self.school }).reject { |user| user == self || user.admin? }
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
      classrooms.includes(:students).each do |classroom|
        classroom.students.each do |student|
          work_plans += WorkPlan.includes(:grade).where(student:, special_wps: false)
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
          work_plans += WorkPlan.includes(:grade).where(student:, special_wps: false)
        end
      end
    end
    work_plans
  end

  def classic_conversations
    Conversation.joins(:user_conversations).where(user_conversations: { user: self }, conversation_type: "classic")
  end

  def classic_and_group_conversations
    Conversation.joins(:user_conversations).where(user_conversations: { user: self },
                                                  conversation_type: %w[classic group])
  end

  private

  def set_defaults
    SchoolRole.create!(user: self, school: School.where(name: "Ensemble").first) if school_role.nil?
    # true
  end

  def transmit_all_challenges
    # get new user <= superteacher
    return if challenges.empty?

    new_user = school.super_teachers.first
    # iterate on challenge and update user
    challenges.each { |challenge| challenge.update(user: new_user) }
  end
end
