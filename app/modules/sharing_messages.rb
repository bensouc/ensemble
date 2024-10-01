# frozen_string_literal: true

module SharingMessages
  def self.send_ensemble_message_to_user(user, html_text)
    # find the ensemble converstion for user
    conversation = Conversation.find_or_create_ensemble(user)
    # create a new message
    new_message = Message.new(conversation:, user: User.find_by(admin: true))
    new_message.content = html_text
    new_message.save!
  end
end
