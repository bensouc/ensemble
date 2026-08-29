require 'rails_helper'

RSpec.describe Grade, type: :model do
  before do
    @school = create(:school)
    @grade = create(:grade, school: @school)
  end

  it " is valid with valid attributes" do
    expect(@grade).to be_valid
  end

  # `shared_classrooms` en `dependent: nil` face à une clé étrangère en RESTRICT :
  # supprimer un niveau contenant une classe partagée levait InvalidForeignKey.
  # Ici la suppression est « en gros », la classe doit bel et bien disparaître.
  describe "#destroy avec une classe partagée" do
    it "emporte la classe et son lien de partage" do
      school = create(:school)
      grade = create(:grade, school:)
      classroom = create(:classroom, grade:)
      share = create(:shared_classroom, classroom:)

      expect { grade.destroy! }.not_to raise_error
      expect(Classroom.exists?(classroom.id)).to be false
      expect(SharedClassroom.exists?(share.id)).to be false
    end
  end

end
