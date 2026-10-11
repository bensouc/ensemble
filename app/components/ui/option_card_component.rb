# frozen_string_literal: true

module Ui
  # Un choix entre quelques façons de faire : un bouton radio en carte, son titre
  # et une phrase qui dit ce qu'il donne. Quand deux boutons d'envoi portaient ces
  # façons, l'aide qui les distinguait se lisait mal.
  class OptionCardComponent < ViewComponent::Base
    def initialize(name:, value:, title:, text:, checked: false)
      super()
      @name = name
      @value = value
      @title = title
      @text = text
      @checked = checked
    end

    def call
      tag.label(class: "ui-option") do
        safe_join([
                    radio_button_tag(@name, @value, @checked, id: nil, class: "ui-option-input"),
                    tag.span(class: "ui-option-body") do
                      safe_join([tag.span(@title, class: "ui-option-title"), tag.span(@text, class: "ui-option-text")])
                    end
                  ])
      end
    end
  end
end
