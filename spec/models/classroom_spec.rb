# frozen_string_literal: true

require "rails_helper"
RSpec.describe Classroom, type: :model do
  before(:all) do
    WorkPlan.destroy_all
    WorkPlanDomain.destroy_all
    Challenge.destroy_all
    SchoolRole.destroy_all
    User.destroy_all
    @classroom1 = create(:classroom)
  end

  it " is valid with valid attributes" do
    expect(@classroom1).to be_valid
  end

  # En `dependent: nil` face à une clé étrangère en RESTRICT, détruire une classe
  # partagée levait `InvalidForeignKey` — y compris en cascade depuis le prof, le
  # niveau ou l'école.
  it { is_expected.to have_many(:shared_classrooms).dependent(:destroy) }

  # Supprimer une classe partagée n'en est pas une suppression : sa propriété
  # passe à l'un des collègues du partage. Le contrôleur portait cette règle à
  # lui seul, elle vit désormais dans le modèle pour valoir partout.
  describe "#destroy_or_hand_over!" do
    let(:school) { create(:school) }
    let(:grade) { create(:grade, school:) }
    let(:owner) { create(:user, admin: false, demo: false) }
    let(:colleague) { create(:user, admin: false, demo: false) }
    let(:other_colleague) { create(:user, admin: false, demo: false) }
    let(:classroom) { create(:classroom, user: owner, grade:) }

    context "quand la classe n'est partagée avec personne" do
      it "la détruit, elle et ses élèves" do
        student = create(:student, classroom:)
        expect { classroom.destroy_or_hand_over! }.to change(Classroom, :count).by(-1)
        expect(Student.exists?(student.id)).to be false
      end

      it "n'y laisse ni result, ni ceinture, ni plan de travail orphelin" do
        student = create(:student, classroom:)
        skill = create(:skill, school:)
        create(:result, student:, skill:)
        create(:belt, student:, domain: skill.domain)
        create(:work_plan, user: owner, grade:, student:)

        classroom.destroy_or_hand_over!

        expect(Result.where(student_id: student.id)).to be_empty
        expect(Belt.where(student_id: student.id)).to be_empty
        expect(WorkPlan.where(student_id: student.id)).to be_empty
      end
    end

    context "quand la classe est partagée" do
      it "ne la détruit pas, et la passe au collègue" do
        create(:shared_classroom, user: colleague, classroom:)

        expect { classroom.destroy_or_hand_over! }.not_to change(Classroom, :count)
        expect(classroom.reload.user).to eq colleague
      end

      it "retire le lien de partage du repreneur, devenu le teacher" do
        share = create(:shared_classroom, user: colleague, classroom:)

        classroom.destroy_or_hand_over!

        expect(SharedClassroom.exists?(share.id)).to be false
      end

      it "conserve les autres partages et les élèves" do
        create(:shared_classroom, user: colleague, classroom:)
        kept = create(:shared_classroom, user: other_colleague, classroom:)
        student = create(:student, classroom:)

        classroom.destroy_or_hand_over!

        expect(classroom.reload.shared_classrooms).to contain_exactly(kept)
        expect(classroom.students).to contain_exactly(student)
      end

      # `first` sans ORDER BY ne désigne pas un repreneur stable : on prend le
      # partage le plus ancien, donc le premier collègue.
      it "choisit le partage le plus ancien" do
        first_share = create(:shared_classroom, user: colleague, classroom:)
        create(:shared_classroom, user: other_colleague, classroom:)

        classroom.destroy_or_hand_over!

        expect(classroom.reload.user).to eq first_share.user
      end

      # Le `save` sans `!` d'avant détruisait le partage alors que le transfert
      # avait échoué : le collègue perdait l'accès à une classe restée chez son
      # propriétaire.
      it "ne détruit aucun partage si le transfert échoue" do
        share = create(:shared_classroom, user: colleague, classroom:)
        classroom.grade = nil

        expect { classroom.destroy_or_hand_over! }.to raise_error(ActiveRecord::RecordInvalid)
        expect(SharedClassroom.exists?(share.id)).to be true
        expect(Classroom.find(classroom.id).user).to eq owner
      end
    end
  end
end
