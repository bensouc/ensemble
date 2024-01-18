# frozen_string_literal: true

class School < ApplicationRecord
  has_many :school_roles # Une école a plusieurs school_roles
  has_many :users, through: :school_roles # Une école a plusieurs utilisateurs à travers schoolRole
  has_many :classrooms, through: :users
  has_many :skills, dependent: :destroy
  has_many :grades, dependent: :destroy
  has_one :subscription, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true

  # TO PROCEED POST CREATION
  after_create do
    Stripe.api_key = ENV["STRIPE_API_KEY"]
    stripe_customer = Stripe::Customer.create({ email:  })
    # stripe_customer_id = stripe_customer.id
    # update(stripe_customer_id: stripe_customer_id)
  end

  # Instance Methods

  def special_domains?
    special_domains
  end

  def valid_subscription?
  subscription&.valid_subscription?
  end
  def super_teachers
    users.where(school_roles: { super_teacher: true })
  end

  def all_students_list
    classrooms.map { |classroom| classroom.students }.flatten
  end
end
