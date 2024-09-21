class Message < ApplicationRecord
  belongs_to :user
  belongs_to :conversation

  # validations
  validates :content, presence: true

  after_create_commit :broadcast_message

  def read?
    read
  end

  def read!
    update(read: true)
  end

  private

  def broadcast_message
  broadcast_append_to "conversation_#{conversation.id}_messages",
                      partial: "messages/message",
                      locals: { message: self, user: user }
  end
end
