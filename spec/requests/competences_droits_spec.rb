# frozen_string_literal: true

require "rails_helper"

# Une compétence appartient à son école par deux chemins : `skill.school` et son
# domaine (`domain.grade.school`). La création posait le premier mais prenait le
# second dans le formulaire, sans contrôle : une compétence créée sous le domaine
# d'une autre école s'affichait chez elle. L'index, l'export et l'import
# prenaient de même le niveau et le domaine dans la requête.
RSpec.describe "Droits sur les compétences", type: :request do
  let(:ecole) { create(:school) }
  let(:enseignant) { create(:user, school: ecole, admin: false) }
  let(:niveau) { create(:grade, school: ecole, name: "CE1", grade_level: "CE1") }
  let!(:domaine) { create(:domain, grade: niveau, name: "Numération", position: 1) }
  let!(:competence) { create(:skill, school: ecole, domain: domaine, level: 1, name: "Compter les dizaines") }

  let(:intrus) { create(:user, admin: false) }
  let(:niveau_intrus) { create(:grade, school: intrus.school, name: "CE1", grade_level: "CE1") }

  def creer(domaine, nom)
    post skills_path, params: { skill: { name: nom, symbol: "◼", level: 1, domain_id: domaine.id } }
  end

  def classeur(nom_domaine, competence)
    package = Axlsx::Package.new
    package.workbook.add_worksheet(name: nom_domaine) do |feuille|
      feuille.add_row %w[Ceinture Symbole Compétences]
      feuille.add_row ["blanche", "◼", competence]
    end
    fichier = Tempfile.new(["classeur", ".xlsx"])
    package.serialize(fichier.path)
    Rack::Test::UploadedFile.new(fichier.path, Mime[:xlsx].to_s, true, original_filename: "competences.xlsx")
  end

  context "pour un enseignant d'une autre école" do
    before do
      create(:classroom, user: intrus, grade: niveau_intrus)
      sign_in intrus
    end

    it "ne crée pas de compétence sous un domaine de l'autre école" do
      expect { creer(domaine, "Intruse") }.not_to change(domaine.skills, :count)
    end

    it "ne parcourt pas ses compétences depuis l'index" do
      get skills_path, params: { grade: niveau.id, domain: domaine.id }

      expect(response.body).not_to include("Compter les dizaines")
    end

    it "n'exporte pas ses compétences" do
      get skills_path(format: :xlsx), params: { grade: niveau.id }

      expect(response).to have_http_status(:forbidden)
    end

    it "ne liste pas les domaines de son niveau" do
      get grade_domains_path(niveau)

      expect(response).to have_http_status(:redirect)
    end

    it "n'importe pas de compétences dans son niveau" do
      post upload_skills_path, params: { liste: { excel_file: classeur(domaine.name, "Intruse"), level: niveau.id } }
      follow_redirect! if response.location&.include?(add_skills_from_xls_path)

      expect(domaine.skills.pluck(:name)).not_to include("Intruse")
    end
  end

  context "pour un enseignant de l'école" do
    before do
      create(:classroom, user: enseignant, grade: niveau)
      sign_in enseignant
    end

    it "crée une compétence sous un domaine de son école" do
      expect { creer(domaine, "Compter les centaines") }.to change(domaine.skills, :count).by(1)
    end

    it "parcourt et exporte ses compétences" do
      get grade_domains_path(niveau)
      expect(response).to have_http_status(:ok)

      get skills_path, params: { grade: niveau.id, domain: domaine.id }
      expect(response.body).to include("Compter les dizaines")

      get skills_path(format: :xlsx), params: { grade: niveau.id }
      expect(response.media_type).to eq(Mime[:xlsx].to_s)
    end

    # Le formulaire d'édition renvoie le domaine et le niveau en champs cachés :
    # la modification les acceptait, et rangeait la compétence sous le domaine
    # d'une autre école à qui forgeait la requête.
    it "ne déplace pas une compétence sous le domaine d'une autre école" do
      domaine_etranger = create(:domain, grade: niveau_intrus, name: "Numération")

      patch skill_path(competence), params: { skill: { name: "Compter les dizaines", domain_id: domaine_etranger.id } }

      expect(competence.reload.domain).to eq(domaine)
    end

    it "renomme une compétence" do
      patch skill_path(competence), params: { skill: { name: "Compter par dizaines", domain_id: domaine.id, level: 1 } }

      expect(competence.reload.name).to eq("Compter par dizaines")
    end
  end

  context "pour un admin d'une autre école" do
    before do
      admin = create(:user, admin: true)
      create(:classroom, user: admin)
      sign_in admin
    end

    it "parcourt et exporte les compétences, liste les domaines" do
      get grade_domains_path(niveau)
      expect(response).to have_http_status(:ok)

      get skills_path, params: { grade: niveau.id, domain: domaine.id }
      expect(response.body).to include("Compter les dizaines")

      get skills_path(format: :xlsx), params: { grade: niveau.id }
      expect(response.media_type).to eq(Mime[:xlsx].to_s)
    end

    # La compétence appartient à l'école de son domaine, pas à celle de l'admin
    # qui la saisit : sinon `school` et `domain.grade.school` divergent.
    it "crée une compétence sous un domaine de l'école" do
      expect { creer(domaine, "Compter les centaines") }.to change(domaine.skills, :count).by(1)
      expect(domaine.skills.find_by(name: "Compter les centaines").school).to eq(ecole)
    end

    it "renomme une compétence" do
      patch skill_path(competence), params: { skill: { name: "Compter par dizaines" } }

      expect(competence.reload.name).to eq("Compter par dizaines")
    end
  end
end
