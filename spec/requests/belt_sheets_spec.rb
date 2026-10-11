# frozen_string_literal: true

require "rails_helper"

# L'éditeur de fiche de ceinture, de la fiche de l'élève jusqu'à l'exercice de
# chaque compétence. Et le cloisonnement : une fiche est celle d'un élève, que
# seuls voient ceux qui voient sa classe.
RSpec.describe "Fiches de ceinture", type: :request do
  let(:school) { create(:school) }
  let(:enseignant) { create(:user, school:, admin: false) }
  let(:grade) { create(:grade, school:, name: "CE1", grade_level: "CE1") }
  let(:classroom) { create(:classroom, user: enseignant, grade:) }
  let(:eleve) { create(:student, classroom:, first_name: "Machin") }
  let!(:numeration) { create(:domain, grade:, position: 1, name: "Numération", special: false) }
  let!(:compter) { create(:skill, domain: numeration, level: 1, school:, name: "Compter jusqu'à 10") }
  let!(:ranger) { create(:skill, domain: numeration, level: 1, school:, name: "Ranger les nombres") }

  before { sign_in enseignant }

  def fiche
    BeltSheet.where(student: eleve).sole
  end

  it "prépare la fiche depuis la fiche de l'élève, et l'ouvre" do
    epreuve = create(:challenge, skill: compter, user: enseignant, for_belt: true, name: "Épreuve compter")

    post student_belt_sheets_path(eleve)

    expect(response).to redirect_to(belt_sheet_path(fiche))
    follow_redirect!
    expect(response.body).to include("Fiche de ceinture — Machin", "Numération", "Compter jusqu&#39;à 10",
                                     "Épreuve compter")
    expect(fiche.belt_sheet_skills.find_by!(skill: compter).challenge).to eq(epreuve)
  end

  it "propose Charger / Créer quand une compétence n'a pas d'exercice de ceinture, et crée l'exercice vide" do
    post student_belt_sheets_path(eleve)
    ligne = fiche.belt_sheet_skills.find_by!(skill: ranger)

    get belt_sheet_path(fiche)
    expect(response.body).to include(create_empty_challenge_belt_sheet_skill_path(ligne))

    post create_empty_challenge_belt_sheet_skill_path(ligne), as: :turbo_stream

    expect(ligne.reload.challenge).to be_for_belt
    expect(ligne.challenge.skill).to eq(ranger)
  end

  it "charge un autre exercice de ceinture depuis le carrousel" do
    premier = create(:challenge, skill: compter, user: enseignant, for_belt: true)
    autre = create(:challenge, skill: compter, user: enseignant, for_belt: true)
    post student_belt_sheets_path(eleve)
    ligne = fiche.belt_sheet_skills.find_by!(skill: compter)
    expect(ligne.challenge).to eq(premier)

    post pick_challenge_belt_sheet_skill_path(ligne), as: :turbo_stream
    expect(response.body).to include(autre.name)

    patch belt_sheet_skill_path(ligne), params: { belt_sheet_skill: { challenge_id: autre.id } }, as: :turbo_stream
    expect(ligne.reload.challenge).to eq(autre)
  end

  it "refuse un exercice classique, ou celui d'une autre compétence, dans une ligne" do
    post student_belt_sheets_path(eleve)
    ligne = fiche.belt_sheet_skills.find_by!(skill: compter)

    classique = create(:challenge, skill: compter, user: enseignant)
    ailleurs = create(:challenge, skill: ranger, user: enseignant, for_belt: true)

    [classique, ailleurs].each do |intrus|
      expect do
        patch belt_sheet_skill_path(ligne), params: { belt_sheet_skill: { challenge_id: intrus.id } }, as: :turbo_stream
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
    expect(ligne.reload.challenge).to be_nil
  end

  it "clone l'exercice de la ligne et met la copie à sa place" do
    epreuve = create(:challenge, skill: compter, user: enseignant, for_belt: true)
    post student_belt_sheets_path(eleve)
    ligne = fiche.belt_sheet_skills.find_by!(skill: compter)

    expect { post clone_challenge_belt_sheet_skill_path(ligne), as: :turbo_stream }.to change(Challenge, :count).by(1)

    expect(ligne.reload.challenge).not_to eq(epreuve)
    expect(ligne.challenge).to be_for_belt
  end

  it "ajoute un domaine à la main, à la ceinture choisie, et le range à sa place" do
    grammaire = create(:domain, grade:, position: 0, name: "Grammaire", special: false)
    verbe = create(:skill, domain: grammaire, level: 2, school:, name: "Le verbe")
    post student_belt_sheets_path(eleve)

    post belt_sheet_belt_sheet_domains_path(fiche),
         params: { belt_sheet_domain: { domain_id: grammaire.id, level: 2 } }, as: :turbo_stream

    expect(fiche.ordered_domains.map(&:domain)).to eq([grammaire, numeration])
    expect(fiche.belt_sheet_domains.find_by!(domain: grammaire).belt_sheet_skills.map(&:skill)).to eq([verbe])
  end

  it "retire puis remet une compétence, et retire un domaine" do
    post student_belt_sheets_path(eleve)
    bloc = fiche.belt_sheet_domains.sole
    ligne = bloc.belt_sheet_skills.find_by!(skill: ranger)

    delete belt_sheet_skill_path(ligne), as: :turbo_stream
    expect(bloc.belt_sheet_skills.reload.map(&:skill)).to eq([compter])

    post belt_sheet_domain_belt_sheet_skills_path(bloc), params: { skill_id: ranger.id }, as: :turbo_stream
    expect(bloc.belt_sheet_skills.reload.map(&:skill)).to eq([compter, ranger])

    delete belt_sheet_domain_path(bloc), as: :turbo_stream
    expect(fiche.belt_sheet_domains).to be_empty
  end

  it "refuse d'ajouter à un bloc la compétence d'une autre ceinture" do
    post student_belt_sheets_path(eleve)
    bloc = fiche.belt_sheet_domains.sole
    autre_ceinture = create(:skill, domain: numeration, level: 3, school:, name: "Plus tard")

    expect do
      post belt_sheet_domain_belt_sheet_skills_path(bloc), params: { skill_id: autre_ceinture.id }, as: :turbo_stream
    end.to raise_error(ActiveRecord::RecordNotFound)
  end

  describe "cloisonnement" do
    let(:autre_ecole) { create(:school) }
    let(:intrus) { create(:user, school: autre_ecole, admin: false) }

    it "ferme la fiche, ses blocs et ses lignes à l'enseignant d'une autre école" do
      post student_belt_sheets_path(eleve)
      bloc = fiche.belt_sheet_domains.sole
      ligne = bloc.belt_sheet_skills.first
      sign_in intrus

      get belt_sheet_path(fiche)
      expect(response).to have_http_status(:redirect)
      expect(response.body).not_to include("Machin")

      expect { post student_belt_sheets_path(eleve) }.not_to change(BeltSheet, :count)
      expect { delete belt_sheet_domain_path(bloc), as: :turbo_stream }.not_to change(BeltSheetDomain, :count)
      expect { post create_empty_challenge_belt_sheet_skill_path(ligne), as: :turbo_stream }.
        not_to change(Challenge, :count)
    end
  end
end
