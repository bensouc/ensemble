# frozen_string_literal: true

require "rails_helper"

RSpec.describe Manipule::Attempt do
  let(:probleme) { create(:manipule_problem) }
  let(:serie) { create(:manipule_practice, skill: probleme.skill) }
  let(:tentative) { serie.attempts.create!(problem: probleme, position: 1) }

  it "démarre en attente" do
    expect(tentative.status).to eq("pending")
    expect(tentative).not_to be_repondue
  end

  it "enregistre un bon choix" do
    tentative.repondre_par_choix!(probleme.choices.find(&:correct?), elapsed_ms: 4200)

    expect(tentative.status).to eq("correct")
    expect(tentative.elapsed_ms).to eq(4200)
    expect(tentative.answered_at).to be_present
  end

  it "enregistre un mauvais choix, et garde lequel" do
    mauvais = probleme.choices.reject(&:correct?).first
    tentative.repondre_par_choix!(mauvais)

    expect(tentative.status).to eq("wrong")
    expect(tentative.choice).to eq(mauvais)
  end

  it "enregistre une saisie en s'appuyant sur la tolérance du problème" do
    probleme_saisie = create(:manipule_problem, :saisie)
    essai = serie.attempts.create!(problem: probleme_saisie, position: 2)

    essai.repondre_par_saisie!("8 pommes")

    expect(essai.status).to eq("correct")
    expect(essai.given).to eq("8 pommes")
  end

  # Le point qui fait que le suivi de l'enseignante ne ment pas : elle verrait
  # un échec là où il y a eu un renoncement.
  it "distingue « passé » de « faux »" do
    tentative.passer!

    expect(tentative.status).to eq("skipped")
    expect(described_class.reussies).to be_empty
    expect(described_class.where(status: "wrong")).to be_empty
    expect(tentative).to be_repondue
  end

  it "compte les réécoutes" do
    expect { 3.times { tentative.ecoute! } }.to change { tentative.reload.listened_count }.from(0).to(3)
  end

  it "refuse un statut inconnu" do
    tentative.status = "perdu"

    expect(tentative).not_to be_valid
  end

  it "refuse deux tentatives au même rang dans une série" do
    tentative
    doublon = serie.attempts.build(problem: probleme, position: 1)

    expect { doublon.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
