# frozen_string_literal: true

require "rails_helper"

RSpec.describe Manipule::Assignment do
  let(:eleve) { create(:student) }
  let(:enseignante) { create(:user) }

  it "désigne une compétence, et une seule à la fois" do
    premiere = create(:manipule_skill)
    seconde = create(:manipule_skill)

    described_class.designer!(student: eleve, skill: premiere, user: enseignante)
    described_class.designer!(student: eleve, skill: seconde, user: enseignante)

    expect(described_class.courante(eleve).skill).to eq(seconde)
    expect(described_class.active.where(student: eleve).count).to eq(1)
  end

  it "garde les affectations passées pour l'historique" do
    2.times { described_class.designer!(student: eleve, skill: create(:manipule_skill), user: enseignante) }

    expect(described_class.where(student: eleve).count).to eq(2)
  end

  it "n'a pas d'affectation courante tant que personne n'a désigné" do
    expect(described_class.courante(eleve)).to be_nil
  end

  it "ne touche pas aux affectations d'un autre élève" do
    autre = create(:student)
    described_class.designer!(student: autre, skill: create(:manipule_skill), user: enseignante)

    described_class.designer!(student: eleve, skill: create(:manipule_skill), user: enseignante)

    expect(described_class.courante(autre)).to be_present
  end
end
