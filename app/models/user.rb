# frozen_string_literal: true

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  validates :first_name, presence: true
  validates :last_name, presence: true

  has_many :classrooms, dependent: :destroy
  has_many :work_plans, dependent: :destroy
  has_many :students, through: :classrooms, dependent: :destroy
  has_many :challenges, dependent: nil

  has_one_attached :avatar
end
