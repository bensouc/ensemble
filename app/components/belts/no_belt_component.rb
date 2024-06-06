# frozen_string_literal: true

class Belts::NoBeltComponent < ViewComponent::Base
  def initialize(student:, domain:)
    @student = student
    @domain = domain
  end

end
