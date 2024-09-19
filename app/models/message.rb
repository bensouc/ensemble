class Message < ApplicationRecord
  belongs_to :user
  belongs_to :conversation

  # validations
  validates :content, presence: true

  def read?
    read
  end

  def read!
    update(read: true)
  end
end
