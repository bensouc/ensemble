require "rails_helper"

RSpec.describe School, type: :model do
  before do
    @school = create(:school)
  end
  it " is valid with valid attributes" do
    expect(@school).to be_valid
  end

  describe "code école" do
    it "est tiré à la création, sans qu'on ait à le saisir" do
      code = create(:school).code
      expect(code).to match(/\A[#{School::CODE_ALPHABET}]{#{School::CODE_LENGTH}}\z/)
    end

    # Le code est recopié à la main, souvent depuis un écran projeté.
    it "évite les caractères qu'on lit de travers" do
      codes = Array.new(30) { School.generate_code }.join
      expect(codes).not_to match(/[0O1IL]/)
    end

    it "n'écrase pas un code fourni" do
      expect(create(:school, code: "ABC123").code).to eq("ABC123")
    end

    it "le range en majuscules, sans les espaces de la saisie" do
      expect(create(:school, code: "  abc123 ").code).to eq("ABC123")
    end

    it "refuse un code déjà pris" do
      create(:school, code: "ABC123")
      expect(build(:school, code: "abc123")).not_to be_valid
    end

    describe "#renew_code!" do
      it "en tire un nouveau, l'ancien ne vaut plus rien" do
        school = create(:school)
        ancien = school.code
        school.renew_code!
        expect(school.code).not_to eq(ancien)
        expect(School.find_by(code: ancien)).to be_nil
      end
    end
  end

  describe "#all_students_list" do
    it "returns a list of all students of this particular School" do
      user1 = create(:user, school: @school)
      user2 = create(:user, school: @school)
      school2 = create(:school)
      user3 = create(:user, school: school2)
      classroom1 = create(:classroom, user: user1)
      classroom2 = create(:classroom, user: user2)
      classroom3 = create(:classroom, user: user3)
      student1 = create(:student, classroom: classroom1)
      student2 = create(:student, classroom: classroom1)
      student3 = create(:student, classroom: classroom2)
      student4 = create(:student, classroom: classroom2)
      student5 = create(:student, classroom: classroom2)
      student6 = create(:student, classroom: classroom3)
      student7 = create(:student, classroom: classroom3)
      expect(@school.all_students_list.count).to eq(5)
    end
  end
end
