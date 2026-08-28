# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClassroomsController, type: :controller do
  let(:school) { create(:school) }
  let(:teacher) { create(:user, admin: false, demo: false) }
  let(:grade) { create(:grade, school:) }

  before do
    school.add_teacher(teacher)
    teacher.reload
    Subscription.create!(school:, status: "active", quantity: 2, rythm: "Annuel",
                         current_period_start: Date.new(2026, 9, 1),
                         current_period_end: Date.new(2027, 8, 31))
    sign_in(teacher)
  end

  def post_classroom
    post :create, params: { classroom: { grade_id: grade.id, name: "Classe test" } }
  end

  describe "#create" do
    it "crée la classe tant que l'abonnement la couvre" do
      expect { post_classroom }.to change(Classroom, :count).by(1)
      expect(response).to redirect_to(classrooms_path)
    end

    # `skip_authorization` laissait le plafond à l'état d'habillage : la policy
    # masquait le formulaire, mais un POST direct créait la classe quand même.
    it "refuse au-delà du nombre de classes payées" do
      2.times { create(:classroom, user: teacher) }
      expect { post_classroom }.not_to change(Classroom, :count)
    end

    it "refuse sous un abonnement résilié" do
      school.subscription.update!(status: "canceled")
      expect { post_classroom }.not_to change(Classroom, :count)
    end

    it "dit pourquoi au lieu de renvoyer en silence" do
      2.times { create(:classroom, user: teacher) }
      post_classroom
      expect(flash[:alert] || flash.now[:alert]).to be_present
    end
  end

  describe "#destroy" do
    let!(:classroom) { create(:classroom, user: teacher, grade:) }
    let(:colleague) { create(:user, admin: false, demo: false) }

    it "détruit une classe qui n'est partagée avec personne" do
      expect { delete :destroy, params: { id: classroom.id } }.to change(Classroom, :count).by(-1)
    end

    # Ce n'est pas un bug : une classe partagée passe au collègue. Le prof qui
    # supprime la voit disparaître de SA liste, d'où l'impression du contraire.
    it "passe une classe partagée au collègue au lieu de la détruire" do
      create(:shared_classroom, user: colleague, classroom:)

      expect { delete :destroy, params: { id: classroom.id } }.not_to change(Classroom, :count)
      expect(classroom.reload.user).to eq colleague
    end

    # La policy acceptait les collègues du partage : un DELETE direct leur
    # donnait la classe, et le propriétaire la perdait.
    it "refuse à un collègue du partage de s'approprier la classe" do
      create(:shared_classroom, user: colleague, classroom:)
      sign_in colleague

      delete :destroy, params: { id: classroom.id }

      expect(classroom.reload.user).to eq teacher
    end
  end

end
