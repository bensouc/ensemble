# frozen_string_literal: true

require "rails_helper"

# L'auteur n'est affiché que dans la liste des exercices (`in_index`), pas dans
# l'éditeur de plan de travail ni le carrousel : c'était donc le seul endroit à
# planter sur un exercice dont l'auteur a quitté l'école.
RSpec.describe "challenges/_challenge" do
  let(:challenge) { create(:challenge) }

  before do
    without_partial_double_verification do
      allow(view).to receive(:policy).
        and_return(instance_double(ChallengePolicy, can_show_delete_button?: false))
    end
  end

  def render_in_index(challenge)
    render partial: "challenges/challenge", locals: { challenge:, in_index: true }
  end

  it "affiche l'auteur quand l'exercice en a un" do
    render_in_index(challenge)

    expect(rendered).to include(challenge.user.first_name)
  end

  it "se rend sans planter, et sans ligne d'auteur, quand il n'en a plus" do
    challenge.update_column(:user_id, nil)

    expect { render_in_index(challenge.reload) }.not_to raise_error
    expect(rendered).not_to include("fa-pen")
    expect(rendered).to include(challenge.name)
  end
end
