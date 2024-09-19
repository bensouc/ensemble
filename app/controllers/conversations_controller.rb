class ConversationsController < ApplicationController
  def index
    @school_conversations = current_user.school_conversations
  end
end
