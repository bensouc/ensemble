# frozen_string_literal: true

class School < ApplicationRecord
  has_many :school_roles, dependent: :destroy # Une école a plusieurs school_roles
  has_many :users, through: :school_roles # Une école a plusieurs utilisateurs à travers schoolRole
  has_many :classrooms, through: :users
  has_many :skills, dependent: :destroy
  has_many :grades, dependent: :destroy
  has_one :subscription, dependent: :destroy

  # Le code que le responsable diffuse pour qu'un collègue rejoigne l'école.
  # L'alphabet écarte ce qui se lit de travers (0/O, 1/I/L) : ce code est recopié
  # à la main, souvent depuis un écran projeté ou un message.
  CODE_ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"
  CODE_LENGTH = 6

  # Validations
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :code, presence: true, uniqueness: true

  # Le code est stocké en majuscules, et la saisie est normalisée de la même
  # façon : un responsable qui dicte son code n'a pas à se soucier de la casse.
  before_validation :normalize_code
  before_validation :assign_code, on: :create

  def self.normalize_code(value)
    value.to_s.strip.upcase.presence
  end

  # Tire un code libre. La boucle couvre la collision : l'index unique en base
  # reste le dernier mot, mais on préfère ne pas y arriver.
  def self.generate_code
    loop do
      candidate = Array.new(CODE_LENGTH) { CODE_ALPHABET.chars.sample }.join
      return candidate unless exists?(code: candidate)
    end
  end

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

  # Coupe l'accès à l'ancien code : un collègue parti, un code lu par-dessus une
  # épaule, et le responsable reprend la main sans passer par nous.
  def renew_code!
    update!(code: self.class.generate_code)
  end

  private

  def normalize_code
    self.code = self.class.normalize_code(code)
  end

  def assign_code
    self.code ||= self.class.generate_code
  end
end
