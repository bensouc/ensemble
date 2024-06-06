# frozen_string_literal: true

class Belts::BeltComponent < ViewComponent::Base
  def initialize(belt:, domain:)
    @belt = belt
    @domain = domain
  end
end
