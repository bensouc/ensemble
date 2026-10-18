# frozen_string_literal: true

require "rails_helper"

# Les listes de classes, sur le bureau et sur le mobile : les siennes d'abord,
# par niveau du CP au CM2 puis par nom ; celles qu'on lui partage ensuite,
# rangées de même. Le bureau triait tout par date de création, et le mobile
# n'affichait pas les classes partagées. Voir > Plans de travail et Voir >
# Ceintures, qui listent leurs dossiers par classe, suivent le même ordre.
RSpec.describe "Ordre des classes", type: :request do
  let(:school) { create(:school) }
  let(:teacher) { create(:user, admin: false, demo: true) }
  let(:collegue) { create(:user, admin: false, demo: true) }

  def niveau(nom)
    Grade.find_by(school:, name: nom) || create(:grade, school:, name: nom, grade_level: nom)
  end

  # Les fiches de ceinture ouvertes partout : Voir > Ceintures ne liste que ces
  # classes-là.
  def classe(nom, niveau_de, user: teacher)
    create(:classroom, user:, grade: niveau(niveau_de), name: nom, belt_sheets: true)
  end

  # Créées dans le désordre : la date de création ne doit plus rien décider.
  before do
    school.add_teacher(teacher)
    school.add_teacher(collegue)
    classe("Les grands", "CM2")
    create(:shared_classroom, user: teacher, classroom: classe("Partagée CE1", "CE1", user: collegue))
    classe("Les petits", "CP")
    create(:shared_classroom, user: teacher, classroom: classe("Partagée CP", "CP", user: collegue))
    classe("B du CE1", "CE1")
    classe("A du CE1", "CE1")
    teacher.reload
    sign_in teacher
  end

  def dans_l_ordre(body, noms)
    positions = noms.map { |nom| body.index(nom) }
    expect(positions).to all(be_present)
    expect(positions).to eq(positions.sort)
  end

  let(:ordre) { ["Les petits", "A du CE1", "B du CE1", "Les grands", "Partagée CP", "Partagée CE1"] }

  it "range les classes du bureau : les siennes par niveau, puis les partagées" do
    get classrooms_path

    dans_l_ordre(response.body, ordre)
  end

  it "range de même celles du mobile, partagées comprises" do
    get mobile_classrooms_path

    dans_l_ordre(response.body, ordre)
  end

  it "range de même les classes de Voir > Plans de travail" do
    get work_plans_path

    dans_l_ordre(response.body, ordre)
  end

  it "range de même les classes de Voir > Ceintures" do
    get belt_sheets_path

    dans_l_ordre(response.body, ordre)
  end
end
