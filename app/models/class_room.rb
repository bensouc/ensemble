class ClassRoom < ApplicationRecord
  belongs_to :user

  validates :grade, presence: true
end
