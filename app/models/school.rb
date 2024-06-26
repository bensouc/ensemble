# frozen_string_literal: true

class School < ApplicationRecord
  has_many :school_roles, dependent: :destroy # Une école a plusieurs school_roles
  has_many :users, through: :school_roles # Une école a plusieurs utilisateurs à travers schoolRole
  has_many :classrooms, through: :users
  has_many :skills, dependent: :destroy
  has_many :grades, dependent: :destroy
  has_one :subscription, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true

  # TO PROCEED POST CREATION
  # STRIPE SWITCH OFF
  # after_create do
  #   Stripe.api_key = ENV["STRIPE_API_KEY"]
  #   stripe_customer = Stripe::Customer.create({ email:  })
  #   # stripe_customer_id = stripe_customer.id
  #   # update(stripe_customer_id: stripe_customer_id)
  # end

  # Instance Methods

  def classrooms_total
    classrooms.count{|classroom| !classroom.user.admin?}
  end

  def add_teacher(teacher, super_teacher = false)
    # remove previous school_roles
    teacher.school_role.destroy
    # create school_role
    SchoolRole.create(user: teacher, school: self, super_teacher:)
  end

  def special_domains?
    special_domains
  end

  def valid_subscription?
    subscription&.active_or_trialing?
  end

  def super_teachers
    users.where(school_roles: { super_teacher: true })
  end

  def super_teachers_first_name

    super_teachers.map  do |teacher|
      teacher.first_name.capitalize
    end.join(super_teachers.count > 1 ? ", " : "")
  end

  def all_students_list
    classrooms.map { |classroom| classroom.students }.flatten
  end
end
