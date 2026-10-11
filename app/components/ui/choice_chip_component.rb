# frozen_string_literal: true

module Ui
  # Un choix en pastille : un bouton radio stylé, son libellé, et en option
  # l'icône de ceinture à la couleur d'un niveau, et une précision en petit.
  # Pour les formulaires en deux temps — un domaine, puis une ceinture.
  #
  #   render Ui::ChoiceChipComponent.new(name: "work_plan[work_plan_domain][level]", value: 3,
  #                                      label: "Orange", belt: 3)
  class ChoiceChipComponent < ViewComponent::Base
    # rubocop:disable Metrics/ParameterLists
    def initialize(name:, value:, label:, belt: nil, hint: nil, checked: false, disabled: false, data: {})
      # rubocop:enable Metrics/ParameterLists
      super()
      @name = name
      @value = value
      @label = label
      @belt = belt
      @hint = hint
      @checked = checked
      @disabled = disabled
      @data = data
    end

    def call
      tag.label(class: ["ui-chip", ("ui-chip--disabled" if @disabled)].compact.join(" ")) do
        safe_join([radio, tag.span(safe_join([icone, @label, precision].compact, " "), class: "ui-chip-body")])
      end
    end

    private

    def radio
      radio_button_tag(@name, @value, @checked, id: nil, class: "ui-chip-input", disabled: @disabled,
                                                required: !@disabled, data: @data)
    end

    def icone
      tag.i(class: "fa-solid fa-bacon ui-chip-belt belt-#{@belt}", aria: { hidden: true }) if @belt
    end

    def precision
      tag.small(@hint, class: "ui-chip-hint") if @hint
    end
  end
end
