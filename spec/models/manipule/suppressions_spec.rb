# frozen_string_literal: true

require "rails_helper"

# Manipule s'accroche aux tables d'Ensemble sans que rien, côté Ensemble, ne
# sache qu'il existe. Ces specs vérifient que son existence n'empêche jamais
# une suppression ordinaire d'Ensemble — c'est exactement ce qui est arrivé.
RSpec.describe "Manipule, ce qui disparaît avec son porteur" do
  let(:enseignante) { create(:user) }
  let(:classe) { create(:classroom, user: enseignante) }
  let(:eleve) { create(:student, classroom: classe) }
  let(:competence) { create(:manipule_skill) }

  def faire_travailler!(eleve)
    probleme = create(:manipule_problem, skill: competence)
    Manipule::Assignment.designer!(student: eleve, skill: competence, user: enseignante)
    serie = Manipule::Practice.create!(student: eleve, skill: competence, started_at: Time.current)
    Manipule::Attempt.create!(practice: serie, problem: probleme, position: 1)
    Manipule::ClassroomToken.pour!(classe)
    probleme
  end

  it "laisse supprimer un élève qui a travaillé" do
    faire_travailler!(eleve)

    expect { eleve.destroy! }.not_to raise_error
    expect(Manipule::Assignment.count).to eq(0)
    expect(Manipule::Practice.count).to eq(0)
  end

  # La suppression d'une classe est une fonction documentée d'Ensemble. Elle
  # tombait dès qu'un élève avait ouvert Manipule une seule fois.
  it "laisse supprimer une classe entière" do
    faire_travailler!(eleve)

    expect { classe.destroy! }.not_to raise_error
    expect(Manipule::ClassroomToken.count).to eq(0)
  end

  it "laisse supprimer la compétence, et emporte ses problèmes" do
    faire_travailler!(eleve)

    expect { competence.destroy! }.not_to raise_error
    expect(Manipule::Problem.count).to eq(0)
    expect(Manipule::Attempt.count).to eq(0)
  end

  # La colonne de l'auteur est volontairement nullable : un problème survit au
  # départ de celle qui l'a écrit, comme les exercices d'Ensemble.
  it "laisse partir l'autrice sans emporter ses problèmes" do
    autrice = create(:user)
    probleme = create(:manipule_problem, skill: competence, user: autrice)

    autrice.destroy!

    expect(probleme.reload.user_id).to be_nil
  end

  it "emporte l'audio avec le problème qui le portait" do
    probleme = create(:manipule_problem, skill: competence)
    rendu = Manipule::Synthese::Rendu.new(octets: "x", content_type: "audio/mpeg", voix: "une voix")
    Manipule::Audio.poser!(readable: probleme, role: "enonce", texte: "un texte", rendu:)
    Manipule::Audio.poser!(readable: probleme.choices.first, role: "choix", texte: "un autre", rendu:)

    expect { probleme.destroy! }.to change(Manipule::Audio, :count).by(-2)
  end
end
