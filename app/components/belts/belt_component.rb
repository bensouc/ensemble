# frozen_string_literal: true

class Belts::BeltComponent < ViewComponent::Base
  # `obtenue` : la ceinture vient de tomber, depuis la modale de validation.
  def initialize(belt:, domain:, obtenue: false)
    @belt = belt
    @domain = domain
    @obtenue = obtenue
  end
end
