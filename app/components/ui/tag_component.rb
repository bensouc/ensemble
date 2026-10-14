# frozen_string_literal: true

module Ui
  # Une étiquette : un mot en petites capitales dans une pastille cerclée de
  # rose — celle de « bêta » dans le menu. Elle dit ce qu'on regarde, elle ne
  # fait rien.
  #
  #   render Ui::TagComponent.new("Fiche de ceinture")
  class TagComponent < ViewComponent::Base
    def initialize(label)
      super()
      @label = label
    end

    def call
      tag.span(@label, class: "ui-tag")
    end
  end
end
