# frozen_string_literal: true

require "rails_helper"

RSpec.describe StudentPolicy do
  let(:school) { create(:school) }
  let(:grade) { create(:grade, school:) }
  let(:teacher) { create(:user, admin: false, demo: false) }
  let(:classroom) { create(:classroom, user: teacher, grade:) }
  let(:student) { create(:student, classroom:) }

  before do
    school.add_teacher(teacher)
    teacher.reload
  end

  # `show?` renvoyait `true` sans condition : la fiche d'un élève — nom,
  # ceintures, progression — était ouverte à tout enseignant connecté, y compris
  # d'une autre école. La règle est maintenant celle de la classe.
  describe "#show?" do
    it "autorise l'enseignant de la classe" do
      expect(described_class.new(teacher, student).show?).to be true
    end

    it "autorise le collègue avec qui la classe est partagée" do
      collegue = create(:user, admin: false, demo: false)
      school.add_teacher(collegue)
      create(:shared_classroom, user: collegue, classroom:)

      expect(described_class.new(collegue, student).show?).to be true
    end

    it "autorise un admin" do
      expect(described_class.new(create(:user, admin: true), student).show?).to be true
    end

    it "refuse un collègue de la même école qui n'a pas la classe" do
      collegue = create(:user, admin: false, demo: false)
      school.add_teacher(collegue)

      expect(described_class.new(collegue, student).show?).to be false
    end

    it "refuse un enseignant d'une autre école" do
      etranger = create(:user, admin: false, demo: false)

      expect(described_class.new(etranger, student).show?).to be false
    end
  end

  # Le transfert reste, lui, à l'échelle de l'école : on déplace un élève entre
  # deux classes du même niveau, qui appartiennent par construction à la même
  # école — y compris vers la classe d'un collègue.
  describe "#transfer?" do
    # `add_teacher` remplace le school_role, mais l'association `school` du user
    # reste mémoïsée sur l'école que lui a donnée la factory : sans `reload`, la
    # comparaison d'écoles se fait sur l'ancienne.
    it "autorise un enseignant de l'école" do
      collegue = create(:user, admin: false, demo: false)
      school.add_teacher(collegue)
      collegue.reload

      expect(described_class.new(collegue, student).transfer?).to be true
    end

    it "refuse un enseignant d'une autre école" do
      etranger = create(:user, admin: false, demo: false)

      expect(described_class.new(etranger, student).transfer?).to be false
    end
  end
end
