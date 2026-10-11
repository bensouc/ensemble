# frozen_string_literal: true

module Ui
  # Un choix exclusif en sélecteur à positions : des boutons radio côte à côte,
  # dans un même rail ; la position choisie se détache en blanc.
  #
  #   render Ui::SegmentedComponent.new(name: "mode", checked: "en_cours",
  #                                     options: { "en_cours" => "Les ceintures de ses plans",
  #                                                "resultats" => "Ses prochaines ceintures" })
  class SegmentedComponent < ViewComponent::Base
    def initialize(name:, options:, checked: nil, label: nil, data: {})
      super()
      @name = name
      @options = options
      @checked = checked.to_s
      @label = label
      @data = data
    end

    def call
      tag.div(class: "ui-segmented", role: "radiogroup", aria: { label: @label }) do
        safe_join(@options.map { |value, texte| position(value.to_s, texte) })
      end
    end

    private

    def position(value, texte)
      tag.label(class: "ui-segmented-option") do
        safe_join([radio_button_tag(@name, value, value == @checked, id: nil, class: "ui-segmented-input", data: @data),
                   tag.span(texte, class: "ui-segmented-label")])
      end
    end
  end
end
