class School < ApplicationRecord
  has_many :school_roles  # Une école a plusieurs school_roles
  has_many :users, through: :school_roles  # Une école a plusieurs utilisateurs à travers schoolRole
  has_many :classrooms, through: :users
  has_many :skills, dependent: :destroy

  def all_students_list
    classrooms.map {|classroom| classroom.students}.flatten
  end
end
