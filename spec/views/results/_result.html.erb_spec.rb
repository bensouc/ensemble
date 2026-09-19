# frozen_string_literal: true

require "rails_helper"

# La cellule verte de la grille de classe. Elle portait un « − » dès qu'un
# résultat était validé en ceinture, sans regarder d'où il venait : celle que
# l'élève avait décrochée sur un exercice de ceinture partait du même clic, et
# le plan de travail continuait de dire l'inverse.
RSpec.describe "results/_result" do
  def render_result(origin)
    result = create(:result, kind: "ceinture", status: "completed", origin:)
    render partial: "results/result", locals: { result: }
    result
  end

  it "propose le « − » sur un résultat posé à la main" do
    result = render_result(Result::DIRECT)

    expect(rendered).to include(result_path(result))
  end

  it "ne le propose pas sur une ceinture née d'une évaluation" do
    result = render_result(Result::EVALUATION)

    expect(rendered).not_to include(result_path(result))
    expect(rendered).to include("fa-circle-check")
  end
end
