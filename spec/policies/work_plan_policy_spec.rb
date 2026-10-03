# frozen_string_literal: true

require "rails_helper"

# Créer un plan, à la main ou par génération, n'est permis que pour un élève
# qu'on suit : ceux de ses classes et des classes qu'un collègue partage.
RSpec.describe WorkPlanPolicy do
  let(:enseignant) { create(:user, admin: false) }
  let(:autre_enseignant) { create(:user, admin: false) }
  let(:eleve) { create(:student, classroom: create(:classroom, user: enseignant)) }
  let(:eleve_d_ailleurs) { create(:student, classroom: create(:classroom, user: autre_enseignant)) }

  def politique(user, student)
    described_class.new(user, WorkPlan.new(student:))
  end

  %i[create? auto_new_wp?].each do |regle|
    describe "##{regle}" do
      it "permet un élève de ses classes" do
        expect(politique(enseignant, eleve).public_send(regle)).to be(true)
      end

      it "permet un élève d'une classe qu'un collègue lui partage" do
        create(:shared_classroom, user: enseignant, classroom: eleve_d_ailleurs.classroom)

        expect(politique(enseignant.reload, eleve_d_ailleurs).public_send(regle)).to be(true)
      end

      it "refuse l'élève d'une classe qui ne lui est ni confiée ni partagée" do
        expect(politique(enseignant, eleve_d_ailleurs).public_send(regle)).to be(false)
      end

      it "permet tout à un admin" do
        expect(politique(create(:user, admin: true), eleve_d_ailleurs).public_send(regle)).to be(true)
      end
    end
  end

  it "laisse créer un plan sans élève" do
    expect(politique(enseignant, nil).create?).to be(true)
  end
end
