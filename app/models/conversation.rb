# frozen_string_literal: true

class Conversation < ApplicationRecord
  has_many :messages, dependent: :destroy
  has_many :user_conversations, dependent: :destroy
  has_many :users, through: :user_conversations

  validates :conversation_type, presence: true, inclusion: { in: %w[ensemble group school classic] }
  validate :unique_ensemble_conversation_per_user, if: -> { conversation_type == "ensemble" }
  scope :classic, -> { where(conversation_type: "classic") }
  scope :school, -> { where(conversation_type: "school") }
  scope :ensemble, -> { includes(:users).where(conversation_type: "ensemble") }

  # get conversation for the ensemble user
  def is_group?
    conversation_type == "group"
  end

  def is_school?
    conversation_type == "school"
  end

  def is_classic?
    conversation_type == "classic"
  end

  def is_ensemble?
    conversation_type == "ensemble"
  end

  def add_user!(user)
    users << user
    self.conversation_type = "group" if users.count > 1
    save
  end

  def unread_messages_for_user?(user)
    messages.any? { |message| !user.have_read?(message) }
  end

  def mark_as_read!(user)
    messages.each { |message| message.mark_as_read! for: user }
  end

  def self.find_or_create_ensemble(user)
    conversation = includes(messages: [:user, :rich_text_content])
      .where(conversation_type: "ensemble")
      .joins(:users).find_by(users: { id: user.id })
    unless conversation
      conversation = create(conversation_type: "ensemble", name: "Ensemble & #{user.first_name}")
      conversation.users << user
    end
    conversation
  end

  # get conversion for the school user
  def self.find_or_create_school_conversation(user)
    # Trouver ou créer la conversation de type "school" pour l'école de l'utilisateur
    school = user.school
    conversation = Conversation.includes([:users, { messages: [:user, :rich_text_content] }])
      .where(conversation_type: "school")
      .joins(users: :school_role)
      .find_by(school_roles: { school_id: school.id })
    unless conversation
      conversation = Conversation.create(conversation_type: "school", name: school.name)
      UserConversation.create(user: user, conversation: conversation)
    end
    conversation
  end

  def self.find_or_create_classic_conversation(user, contact)
    conversation = user.conversations.classic.joins(:users).find_by(users: { id: contact.id })
    unless conversation
      conversation = Conversation.create!(conversation_type: "classic", name: "#{contact.first_name} & #{user.first_name}")
      UserConversation.create(user: user, conversation: conversation)
      UserConversation.create(user: contact, conversation: conversation)
    end
    conversation
  end

  private

  def unique_ensemble_conversation_per_user
    users.each do |user|
      if user.conversations.ensemble.exists?
        errors.add(:base, "A user can only have one 'ensemble' conversation.")
        break
      end
    end
  end
end
