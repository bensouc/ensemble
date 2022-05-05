class Belt < ApplicationRecord

  BELT_COLORS = %w(blanche jaune orange verte bleue marron noire)
  belongs_to :student

  def completed?
    self.completed
  end

  def self.update_or_create_by(args, completed)
    obj = self.find_or_create_by(args)
    obj.update(completed)
    return obj
  end
end
