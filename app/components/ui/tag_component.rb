# frozen_string_literal: true

module Ui
  # Une étiquette : un mot en petites capitales dans une pastille cerclée de
  # rose — celle de « bêta » dans le menu. Elle dit ce qu'on regarde, elle ne
  # fait rien.
  #
  # `pastille` : une classe de couleur pour l'embout gauche de l'étiquette — la
  # couleur d'une ceinture (`belt-bg-3`) quand elle dit où celle-ci en est.
  #
  #   render Ui::TagComponent.new("Fiche de ceinture")
  #   render Ui::TagComponent.new("En cours", pastille: "belt-bg-3")
  class TagComponent < ViewComponent::Base
    def initialize(label, pastille: nil)
      super()
      @label = label
      @pastille = pastille
    end

    def call
      tag.span(class: ["ui-tag", ("ui-tag--pastille" if @pastille)]) { safe_join([pastille_tag, @label].compact) }
    end

    private

    def pastille_tag
      tag.span(class: ["ui-tag-pastille", @pastille], aria: { hidden: true }) if @pastille
    end
  end
end
