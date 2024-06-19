# frozen_string_literal: true

class Btns::ValidateComponent < ViewComponent::Base
  def initialize(btn_text:, btn_class:, btn_data: {})
    @btn_text = btn_text
    @btn_class = btn_class
    @btn_data = btn_data.map { |k, v| "data-#{k}=#{v}" }.join(' ')
  end
end
