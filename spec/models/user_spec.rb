# frozen_string_literal: true

require "rails_helper"
RSpec.describe User, type: :model do

  it { is_expected.to have_many(:user_conversations).dependent(:destroy) }
  it { is_expected.to have_many(:conversations).through(:user_conversations) }
  it { is_expected.to have_many(:messages).dependent(:destroy) }

  before do
    @user1 = create(:user)
  end

  it "is valid with valid attributes" do
    expect(@user1).to be_valid
    # p @user1
  end

  it "has a unique email" do
    user2 = build(:user, email: @user1.email)
    expect(user2).to_not be_valid
  end

  it "is not valid without a password" do
    user2 = build(:user, password: nil)
    expect(user2).to_not be_valid
  end

  it "is not valid without a username" do
    user2 = build(:user, first_name: nil)
    expect(user2).to_not be_valid
  end

  it "is not valid without an email" do
    user2 = build(:user, email: nil)
    expect(user2).to_not be_valid
  end

  # La suppression d'un compte suit la même règle que celle d'une classe : une
  # classe partagée passe au collègue, elle ne disparaît pas avec son
  # propriétaire. Elle butait en réalité sur trois clés étrangères.
  describe "#destroy quand le prof possède une classe partagée" do
    let(:school) { create(:school) }
    let(:grade) { create(:grade, school:) }
    let(:owner) { create(:user, admin: false, demo: false) }
    let(:colleague) { create(:user, admin: false, demo: false) }
    let!(:classroom) { create(:classroom, user: owner, grade:) }
    let!(:share) { create(:shared_classroom, user: colleague, classroom:) }

    it "ne lève pas" do
      expect { owner.destroy! }.not_to raise_error
    end

    it "laisse la classe au collègue, avec ses élèves" do
      student = create(:student, classroom:)

      owner.destroy!

      expect(classroom.reload.user).to eq colleague
      expect(classroom.students).to contain_exactly(student)
    end

    it "détruit en revanche ses classes non partagées" do
      solo = create(:classroom, user: owner, grade:)

      owner.destroy!

      expect(Classroom.exists?(solo.id)).to be false
    end

    # La cession des exercices à un « super teacher » échouait dès que le
    # repreneur désigné était le partant lui-même — et bloquait alors la
    # suppression du compte. Un exercice tient à son grade, pas à son auteur.
    it "laisse ses exercices en place, sans auteur" do
      challenge = create(:challenge, user: owner)

      owner.destroy!

      expect(Challenge.exists?(challenge.id)).to be true
      expect(challenge.reload.user).to be_nil
    end

    # `work_plans.shared_user_id` en `dependent: nil` bloquait aussi.
    it "départage les plans de travail qu'on lui avait partagés, sans les détruire" do
      work_plan = create(:work_plan, user: colleague, grade:, shared_user: owner)

      owner.destroy!

      expect(WorkPlan.exists?(work_plan.id)).to be true
      expect(work_plan.reload.shared_user).to be_nil
    end
  end

end
