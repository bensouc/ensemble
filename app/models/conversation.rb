# frozen_string_literal: true
#
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
end
