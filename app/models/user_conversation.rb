# frozen_string_literal: true

class UserConversation < ApplicationRecord
  # `optional` : les colonnes acceptent NULL en base. À resserrer (NOT NULL, puis
  # `optional` retiré) une fois les lignes vides comptées en production.
  belongs_to :user, optional: true
  belongs_to :conversation, optional: true

  # l index validates l unicite de la conversation pour un user
end
