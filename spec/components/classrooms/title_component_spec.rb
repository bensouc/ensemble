# frozen_string_literal: true

require "rails_helper"

RSpec.describe Classrooms::TitleComponent, type: :component do
  let(:grade) { create(:grade, name: "CE2", grade_level: "CE2") }

  it "montre le nom, et le niveau en petit à sa droite" do
    titre = render_inline(described_class.new(classroom: build(:classroom, grade:, name: "CE2 A")))

    expect(titre.text).to eq("CE2 A CE2")
    expect(titre.at_css("small.classroom-title-grade").text).to eq("CE2")
  end

  it "montre le niveau seul, sans tiret qui pend, quand la classe n'a pas de nom" do
    titre = render_inline(described_class.new(classroom: build(:classroom, grade:, name: nil)))

    expect(titre.text).to eq("CE2")
    expect(titre.at_css("small")).to be_nil
  end

  it "échappe le nom donné par l'enseignant" do
    titre = render_inline(described_class.new(classroom: build(:classroom, grade:, name: "<b>X</b>")))

    expect(titre.at_css("b")).to be_nil
    expect(titre.text).to include("<b>X</b>")
  end
end
