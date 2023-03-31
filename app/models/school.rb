class School < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :classrooms, through: :users
  has_many :skills, dependent: :destroy
end
