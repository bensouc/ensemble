class AddUniqueIndexToUserConversations < ActiveRecord::Migration[7.0]
  def change
    add_index :user_conversations, [:user_id, :conversation_id], unique: true
  end
end
