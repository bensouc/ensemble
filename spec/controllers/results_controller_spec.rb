# frozen_string_literal: true

require "rails_helper"

RSpec.describe ResultsController, type: :controller do
  # Une école cohérente de bout en bout : le recalcul de ceinture cherche les
  # compétences de l'école de l'élève, et les factories, laissées à elles-mêmes,
  # lui en donnent une autre que celle de la compétence.
  let(:school) { create(:school) }
  let(:user) { create(:user, school:) }
  let(:grade) { create(:grade, school:, name: "CM1", grade_level: "CM1") }
  let(:classroom) { create(:classroom, user:, grade:) }
  let(:student) { create(:student, classroom:) }
  let(:domain) { create(:domain, grade:, name: "Calcul", special: false) }
  let(:skill) { create(:skill, domain:, level: 1, school:) }

  before { sign_in user }

  # Le « + » de la grille de classe : une ceinture accordée à la main, qui se
  # retire donc à la main.
  describe "#create" do
    it "marque le résultat comme posé à la main" do
      post :create, params: { result: { student_id: student.id, skill_id: skill.id,
                                        status: "completed", kind: "ceinture" } },
                    format: :turbo_stream

      expect(Result.find_by(student:, skill:)).
        to have_attributes(origin: Result::DIRECT, status: "completed", kind: "ceinture")
    end
  end

  describe "#destroy" do
    # Une ceinture décrochée par l'élève sur un exercice de ceinture se corrige
    # depuis le plan de travail. La grille de classe la retirait d'un clic, et
    # le plan de travail continuait de dire l'inverse.
    it "refuse de retirer une ceinture née d'une évaluation" do
      result = create(:result, student:, skill:, kind: "ceinture", status: "completed",
                               origin: Result::EVALUATION)

      expect do
        delete :destroy, params: { id: result.id }, format: :turbo_stream
      end.not_to change(Result, :count)

      expect(result.reload).to be_present
    end

    it "retire ce qui a été posé à la main, et recalcule la ceinture" do
      result = create(:result, student:, skill:, kind: "ceinture", status: "completed",
                               origin: Result::DIRECT)
      expect(Belt.find_by(student:, domain:, level: 1).completed).to be true

      expect do
        delete :destroy, params: { id: result.id }, format: :turbo_stream
      end.to change(Result, :count).by(-1)

      # `Result` ne prévient ses ceintures que sur `:create` et `:update` : sans
      # l'appel explicite du contrôleur, la ceinture resterait validée.
      expect(Belt.find_by(student:, domain:, level: 1).completed).to be false
    end
  end
end
