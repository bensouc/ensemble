# frozen_string_literal: true

class Conversation < ApplicationRecord
  has_many :messages, dependent: :destroy
  has_many :user_conversations, dependent: :destroy
  has_many :users, through: :user_conversations

  validates :conversation_type, presence: true, inclusion: { in: %w[ensemble grade school classic] }

  def self.find_or_create_ensemble(user)
    conversation = where(conversation_type: "ensemble").joins(:users).find_by(users: { id: user.id })
    unless conversation
      conversation = create(conversation_type: "ensemble", name: "Ensemble")
      conversation.users << user
    end
    conversation
  end
  # get conversion for the school user
  def self.find_or_create_school_conversation(user)
    # Trouver ou créer la conversation de type "school" pour l'école de l'utilisateur
    school = user.school
    conversation = Conversation
      .where(conversation_type: "school")
      .joins(users: :school_role)
      .find_by(school_roles: { school_id: school.id })
    unless conversation
      conversation = Conversation.create(conversation_type: "school", name: school.name)
      UserConversation.create(user: user, conversation: conversation)
    end
    conversation
  end
end
