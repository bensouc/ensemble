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

  # Les comptes admin (support Vroad) créent des classes de test dans les écoles
  # qu'ils accompagnent : elles ne consomment pas le quota payé. `admin` est
  # nullable, d'où le `[false, nil]` — un `where.not(admin: true)` écarterait
  # aussi les NULL, que Postgres ne compare jamais à `true`.
  def teacher_classrooms
    classrooms.where(users: { admin: [false, nil] })
  end

  # Mémoïsé : la policy le compte pour décider, puis la vue le recompte pour
  # l'afficher — deux fois la même jointure schools → school_roles → users →
  # classrooms sur chaque rendu d'un groupe au plafond.
  #
  # Le compte est donc figé pour la durée de vie de l'instance : si un jour on
  # crée une classe puis qu'on relit ce compte sur le MÊME objet, il faudra
  # recharger l'école. Aucun chemin ne le fait aujourd'hui — la création
  # redirige.
  def classrooms_total
    @classrooms_total ||= teacher_classrooms.count
  end

  # Combien de classes au-delà de ce qui est payé. Négatif s'il reste de la place.
  def classrooms_surplus
    classrooms_total - subscription&.quantity.to_i
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

  # `strip` avant `capitalize` : les espaces saisis à l'inscription se voyaient
  # dans les messages, « (Benoît ) ». La mise en phrase revient à la vue, elle
  # seule sait s'il faut « ou » ou « et ».
  def super_teachers_first_names
    super_teachers.filter_map { |teacher| teacher.first_name&.strip.presence&.capitalize }
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
