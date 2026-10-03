# frozen_string_literal: true

require "rails_helper"

# L'aller-retour complet : envoi du classeur (upload_skills_xlsx), puis création
# des compétences (add_skills_from_xls), qui relit le fichier par la session.
# Aucune spec ne le couvrait : un `binding.pry` y est resté, qui en production
# faisait finir l'import en 500 une fois les compétences créées.
RSpec.describe "Import des compétences depuis un classeur Excel", type: :request do
  let(:user) { create(:user) }
  let(:grade) { create(:grade, school: user.school) }
  let!(:domaine) { create(:domain, grade:, name: "Numération", special: false) }

  before { sign_in user }

  # Le même format que l'export (Xlsx.skills_generate_xlsx_file) : un onglet par
  # domaine, une ligne d'en-tête.
  def classeur(lignes, nom: "competences.xlsx")
    package = Axlsx::Package.new
    package.workbook.add_worksheet(name: domaine.name) do |feuille|
      feuille.add_row %w[Ceinture Symbole Compétences]
      lignes.each { |ligne| feuille.add_row ligne }
    end
    fichier = Tempfile.new(["classeur", ".xlsx"])
    package.serialize(fichier.path)
    Rack::Test::UploadedFile.new(fichier.path, Mime[:xlsx].to_s, true, original_filename: nom)
  end

  def importer(fichier)
    post upload_skills_path, params: { liste: { excel_file: fichier, level: grade.id } }
  end

  it "crée les compétences du classeur et revient à la liste" do
    importer(classeur([["blanche", "◼", "Compter jusqu'à 10"], ["jaune", "⬥", "Compter jusqu'à 100"]]))
    expect(response).to redirect_to(add_skills_from_xls_path)

    expect { follow_redirect! }.to change(domaine.skills, :count).by(2)

    expect(response).to redirect_to(skills_path)
    expect(flash[:success]).to eq("2 Compétences ajoutées")
    expect(domaine.skills.pluck(:name, :level)).
      to contain_exactly(["Compter jusqu'à 10", 1], ["Compter jusqu'à 100", 2])
  end

  it "signale une ligne sans ceinture" do
    importer(classeur([[nil, "◼", "Sans ceinture"]]))
    follow_redirect!

    expect(flash[:error]).to eq("vous avez des erreurs")
  end

  it "écrit le classeur sous un nom aléatoire, puis l'efface" do
    importer(classeur([["blanche", "◼", "Compter jusqu'à 10"]], nom: "../../config/master.xlsx"))
    chemin = session[:uploaded_file_path]

    expect(File.dirname(chemin)).to eq(Rails.root.join("tmp").to_s)
    expect(File.basename(chemin)).to match(/\Aimport_competences_\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\.xlsx\z/)

    follow_redirect!
    expect(File).not_to exist(chemin)
  end
end
