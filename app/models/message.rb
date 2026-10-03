class Message < ApplicationRecord
  # `optional` : les colonnes acceptent NULL en base. À resserrer (NOT NULL, puis
  # `optional` retiré) une fois les lignes vides comptées en production.
  belongs_to :user, optional: true
  belongs_to :conversation, optional: true
  has_rich_text :content

  acts_as_readable on: :created_at
  # The `on:` option sets the relevant attribute for comparing timestamps.

  # validations
  validates :content, presence: true

  after_create_commit :broadcast_message

  private

  def broadcast_message
    broadcast_append_to "conversation_#{conversation.id}_messages",
                        partial: "messages/message",
                        locals: { message: self, user: user }
  end
end
