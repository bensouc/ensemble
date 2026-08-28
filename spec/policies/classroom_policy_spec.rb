# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClassroomPolicy do
  subject(:policy) { described_class.new(user, Classroom.new(user:)) }

  let(:school) { create(:school) }
  let(:user) { create(:user, admin: false, demo: false) }

  def subscribe(status: "active", quantity: 3)
    Subscription.create!(school:, status:, quantity:, rythm: "Annuel",
                         current_period_start: Date.new(2026, 9, 1),
                         current_period_end: Date.new(2027, 8, 31))
  end

  def add_classrooms(count, to: user)
    count.times { create(:classroom, user: to) }
    user.reload
  end

  before do
    school.add_teacher(user)
    user.reload
  end

  describe "plafond de classes" do
    # `quantity >= classrooms.count` comparait au décompte d'AVANT création :
    # une école qui payait 3 classes en obtenait 4.
    it "s'arrête au nombre de classes payées, pas une de plus" do
      subscribe(quantity: 3)
      add_classrooms(2)
      expect(policy.create?).to be true

      add_classrooms(1)
      expect(policy.create?).to be false
    end

    it "compte les classes de toute l'école, pas seulement les siennes" do
      subscribe(quantity: 2)
      colleague = create(:user, admin: false, demo: false)
      school.add_teacher(colleague)
      add_classrooms(2, to: colleague)
      expect(policy.create?).to be false
    end

    # Le support crée des classes de test dans les écoles qu'il accompagne.
    it "ne fait pas payer les classes créées par un admin" do
      subscribe(quantity: 2)
      support = create(:user, admin: true)
      school.add_teacher(support)
      add_classrooms(2, to: support)
      expect(policy.create?).to be true
    end
  end

  describe "statut de l'abonnement" do
    # `subscription.nil?` laissait passer une ligne résiliée : seule la
    # suppression de l'abonnement fermait l'accès, jamais sa résiliation.
    %w[active trialing past_due].each do |statut|
      it "laisse créer sous un abonnement #{statut}" do
        subscribe(status: statut)
        expect(policy.create?).to be true
      end
    end

    %w[canceled unpaid ended incomplete pause].each do |statut|
      it "refuse sous un abonnement #{statut}" do
        subscribe(status: statut)
        expect(policy.create?).to be false
      end
    end

    it "refuse sans aucun abonnement" do
      expect(policy.create?).to be false
    end

    it "refuse un abonnement sans quantité" do
      subscribe(quantity: nil)
      expect(policy.create?).to be false
    end
  end

  describe "comptes particuliers" do
    # `user.admin? || user.demo ? … : true` se lisait `(admin? || demo) ? … : true`.
    it "ne plafonne plus l'admin à une seule classe" do
      support = create(:user, admin: true)
      school.add_teacher(support)
      create(:classroom, user: support)
      expect(described_class.new(support.reload, Classroom.new(user: support)).create?).to be true
    end

    it "garde le compte démo à une classe" do
      demo = create(:user, admin: false, demo: true)
      expect(described_class.new(demo, Classroom.new(user: demo)).create?).to be true
      create(:classroom, user: demo)
      expect(described_class.new(demo.reload, Classroom.new(user: demo)).create?).to be false
    end
  end

  # `user_is_owner_or_admin?` acceptait les collègues du partage : un DELETE
  # direct sur /classrooms/:id leur donnait la propriété de la classe, et le
  # propriétaire la perdait. Se séparer d'une classe est la décision du seul
  # propriétaire ; un collègue, lui, supprime son lien de partage.
  describe "#destroy?" do
    let(:grade) { create(:grade, school:) }
    let(:owner) { create(:user, admin: false, demo: false) }
    let(:colleague) { create(:user, admin: false, demo: false) }
    let(:classroom) { create(:classroom, user: owner, grade:) }

    before { create(:shared_classroom, user: colleague, classroom:) }

    it "autorise le propriétaire" do
      expect(described_class.new(owner, classroom).destroy?).to be true
    end

    it "refuse le collègue du partage" do
      expect(described_class.new(colleague, classroom).destroy?).to be false
    end

    it "autorise un admin" do
      expect(described_class.new(create(:user, admin: true), classroom).destroy?).to be true
    end
  end

end
