# frozen_string_literal: true

class UserConversation < ApplicationRecord
  belongs_to :user
  belongs_to :conversation

  # l index validates l unicite de la conversation pour un user
end
