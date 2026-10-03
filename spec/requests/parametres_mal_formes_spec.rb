# frozen_string_literal: true

require "rails_helper"

# `params.expect` (Rails 8) au lieu de `params.require(...).permit(...)` : un
# paramètre mal formé — une chaîne là où l'on attend un hash — donnait une
# erreur 500 (`permit` appelé sur une String). Il répond désormais 400, comme
# un paramètre absent.
RSpec.describe "Paramètres mal formés", type: :request do
  let(:enseignant) { create(:user, admin: false) }
  let(:conversation) { create(:conversation, users: [enseignant], conversation_type: "classic") }

  before { sign_in enseignant }

  it "se soldent par un 400 en production" do
    expect(ActionDispatch::ExceptionWrapper.status_code_for_exception("ActionController::ParameterMissing")).to eq(400)
  end

  it "refuse un renommage de conversation dont le paramètre n'est pas un hash" do
    expect { patch conversation_path(conversation), params: { conversation: "Piraté" } }.
      to raise_error(ActionController::ParameterMissing)
    expect(conversation.reload.name).to eq("Ensemble")
  end

  it "refuse une création de plan dont le paramètre n'est pas un hash" do
    expect { post work_plans_path, params: { work_plan: "Semaine 41" } }.
      to raise_error(ActionController::ParameterMissing)
  end
end
