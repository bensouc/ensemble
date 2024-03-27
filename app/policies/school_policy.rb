class SchoolPolicy < ApplicationPolicy
  class Scope < Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      user.school
    end
  end

  def new?
    true
  end
  
  def create?
    true
  end

  def join?
    true
  end

  def show?
    record.users.any? { |school_user| school_user == user }
  end


end
