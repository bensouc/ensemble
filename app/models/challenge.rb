class Challenge < ApplicationRecord
  belongs_to :skill
  belongs_to :user
  has_rich_text :content
end
