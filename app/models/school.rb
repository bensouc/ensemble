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

  # Les comptes admin (support Vroad) créent des classes de test dans les écoles
  # qu'ils accompagnent : elles ne consomment pas le quota payé. `admin` est
  # nullable, d'où le `[false, nil]` — un `where.not(admin: true)` écarterait
  # aussi les NULL, que Postgres ne compare jamais à `true`.
  def teacher_classrooms
    classrooms.where(users: { admin: [false, nil] })
  end

  def classrooms_total
    teacher_classrooms.count
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

  # `strip` avant `capitalize` : les espaces saisis à l'inscription se voyaient
  # dans les messages, « (Benoît ) ». La mise en phrase revient à la vue, elle
  # seule sait s'il faut « ou » ou « et ».
  def super_teachers_first_names
    super_teachers.filter_map { |teacher| teacher.first_name&.strip.presence&.capitalize }
  end

  def all_students_list
    classrooms.map { |classroom| classroom.students }.flatten
  end
end
