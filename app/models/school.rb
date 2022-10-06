class School < ApplicationRecord
  has_many :users
  has_many :classrooms, through: :users
end
