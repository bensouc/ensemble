# frozen_string_literal: true

class User < ApplicationRecord
  DEMO_CLASSROOM_LIMIT = 1
  DEMO_STUDENT_LIMIT = 5
  STUDENT_LIMIT = 25
  DISCOVERY_METHOD = ["Bouche-à-oreille", "Recherche sur Internet", "Réseaux sociaux", "Publicité en ligne",
                      "Article de presse ou blog", "Événement ou conférence", "Autre"].freeze
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  before_validation :set_defaults

  # Les classes partagées que ce prof possède passent à un collègue du partage au
  # lieu de disparaître avec lui — la même règle que la suppression d'une classe.
  #
  # `prepend: true` est indispensable : `has_many :classrooms, dependent: :destroy`
  # pose son propre `before_destroy`, il faut passer AVANT lui, sinon la classe et
  # ses élèves sont détruits sous les pieds des collègues.
  before_destroy :hand_over_shared_classrooms, prepend: true

  # associations
  devise :invitable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :lastseenable

  # belongs_to :school
  has_one :school_role, dependent: :destroy # Un utilisateur a une seule school_role
  has_one :school, through: :school_role # Un utilisateur appartient à une seule école à travers schoolRole
  has_one :subscription, through: :school
  has_many :classrooms, dependent: :destroy
  has_many :work_plans, dependent: :destroy
  # `:nullify` et non `nil` : le plan de travail reste à son propriétaire, il
  # n'est simplement plus partagé avec le prof qui part. En `nil`, la clé
  # étrangère `work_plans.shared_user_id` empêchait de supprimer son compte.
  has_many :shared_work_plans, class_name: "WorkPlan", foreign_key: "shared_user_id",
                               dependent: :nullify
  has_many :shared_classrooms, dependent: :destroy
  has_many :user_shared_classrooms, through: :shared_classrooms, source: "classroom"
  has_many :students, through: :classrooms, dependent: :destroy
  # Un exercice survit à son auteur : ce qui le rattache à l'école est son grade
  # (`skill → domain → grade`), pas la personne qui l'a écrit. On coupe donc le
  # lien. En `nil`, `challenges.user_id` bloquait la suppression du compte.
  has_many :challenges, dependent: :nullify
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

  def unread_message? # check if user has unread messages true=> has unread messages / false=> no unread messages
    !Message.joins(conversation: :user_conversations).
      where(user_conversations: { user_id: id }).
      unread_by(self).
      empty?
  end

  def admin?
    admin == true
  end

  def demo?
    demo == true
  end

  # Un compte invité existe avant d'être accepté : il n'a encore ni prénom ni
  # nom, et n'a jamais ouvert l'application.
  def invitation_pending?
    invited_to_sign_up?
  end

  # `first_name.capitalize` plantait sur les comptes invités. L'email en dernier
  # recours : c'est la seule chose qu'on connaisse d'eux.
  def display_name
    [first_name, last_name].filter_map { |part| part&.strip.presence&.capitalize }.join(" ").presence || email
  end

  # `school_role` peut manquer (inscription abandonnée avant la création de
  # l'école) : la barre de navigation appelle cette méthode à chaque page, un nil
  # y rendait l'app entière inutilisable pour ce compte.
  def super_teacher?
    school_role&.super_teacher == true
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

  # Les invités en attente sont écartés : partager une classe ou ouvrir une
  # conversation avec un compte qui n'a jamais été ouvert n'a pas de sens, et
  # ils s'affichaient sans nom.
  def collegues
    school.users.reject { |user| user == self || user.admin? || user.invitation_pending? }
  end

  def collegues_with_avatars
    User.includes([avatar_attachment: :blob]).joins(:school_role).
      where(school_roles: { school: school }).
      reject { |user| user == self || user.admin? || user.invitation_pending? }
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
    Conversation.includes(messages: [:user, :rich_text_content]).joins(:user_conversations).where(user_conversations: { user: self },
                                                                                                  conversation_type: %w[
                                                                                                    classic group
                                                                                                  ])
  end

  private

  def set_defaults
    SchoolRole.create!(user: self, school: School.where(name: "Ensemble").first) if school_role.nil?
    # true
  end

  def hand_over_shared_classrooms
    classrooms.joins(:shared_classrooms).distinct.to_a.each(&:destroy_or_hand_over!)
  end
end
