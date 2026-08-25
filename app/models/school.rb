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
    classrooms.count { |classroom| !classroom.user.admin? }
  end

  # `school_role` peut manquer (inscription abandonnée avant la création de
  # l'école) : sans le `&.`, intégrer un tel compte plantait au lieu de marcher.
  def add_teacher(teacher, super_teacher = false)
    # remove previous school_roles
    teacher.school_role&.destroy
    # create school_role
    SchoolRole.create(user: teacher, school: self, super_teacher:)
  end

  def special_domains?
    special_domains
  end

  def valid_subscription?
    subscription&.active_or_trialing?
  end

  # Invite un collègue à créer son compte, déjà rattaché à cette école.
  # `skip_invitation` retarde l'envoi : le mail nomme l'école, il ne peut donc
  # partir qu'une fois le rattachement fait.
  def invite_teacher(email, invited_by)
    invited = User.invite!({ email:, demo: false }, invited_by) { |user| user.skip_invitation = true }
    return invited if invited.errors.any?

    add_teacher(invited)
    invited.reload.deliver_invitation
    invited
  end

  def super_teachers
    users.where(school_roles: { super_teacher: true })
  end

  def super_teachers_first_name
    super_teachers.map do |teacher|
      teacher.first_name.capitalize
    end.join(super_teachers.count > 1 ? ", " : "")
  end

  def all_students_list
    classrooms.map { |classroom| classroom.students }.flatten
  end
end
