# frozen_string_literal: true

require "rails_helper"

RSpec.describe Manipule::ClassroomToken do
  let(:classe) { create(:classroom) }

  it "se donne un jeton long et aléatoire" do
    jeton = described_class.pour!(classe)

    expect(jeton.token.length).to be >= 20
    expect(described_class.pour!(create(:classroom)).token).not_to eq(jeton.token)
  end

  it "n'en crée qu'un par classe" do
    premier = described_class.pour!(classe)

    expect(described_class.pour!(classe)).to eq(premier)
    expect(described_class.where(classroom: classe).count).to eq(1)
  end

  # Renouveler, c'est fermer l'ancienne adresse : c'est le seul recours quand un
  # lien a circulé plus loin que la classe.
  it "ferme l'ancienne adresse quand on renouvelle" do
    jeton = described_class.pour!(classe)
    ancien = jeton.token

    jeton.renouveler!

    expect(jeton.reload.token).not_to eq(ancien)
    expect(described_class.find_by(token: ancien)).to be_nil
  end
end
