# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ui::TagComponent, type: :component do
  it "pose le mot dans une pastille" do
    page = render_inline(described_class.new("Fiche de ceinture"))

    expect(page.at_css("span.ui-tag").text).to eq("Fiche de ceinture")
  end
end
