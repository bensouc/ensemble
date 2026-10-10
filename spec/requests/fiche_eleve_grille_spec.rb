# frozen_string_literal: true

require "rails_helper"

# La grille de progression de la fiche élève — une case par domaine et par
# niveau — est rendue avec la page. Chaque case était un turbo-frame paresseux
# qui rappelait le serveur : 49 requêtes HTTP pour 7 domaines, et une dizaine de
# requêtes SQL par case.
RSpec.describe "Grille de progression de la fiche élève", type: :request do
  let(:school) { create(:school) }
  let(:enseignant) { create(:user, school:, admin: false) }
  let(:grade) { create(:grade, school:, name: "CE2", grade_level: "CE2") }
  let(:eleve) { create(:student, classroom: create(:classroom, user: enseignant, grade:)) }
  let!(:numeration) { create(:domain, grade:, position: 1, name: "Numération", special: false) }
  let!(:calcul) { create(:domain, grade:, position: 2, name: "Calcul", special: false) }

  def case_de(domain, level)
    Nokogiri::HTML(response.body).at_css("turbo-frame#student_#{eleve.id}domain_#{domain.id}_level#{level}")
  end

  before { sign_in enseignant }

  it "rend chaque case avec la page, sans la rappeler au serveur" do
    get student_path(eleve)

    frames = Nokogiri::HTML(response.body).css("turbo-frame[id^='student_#{eleve.id}domain_']")
    expect(frames.size).to eq(2 * WorkPlanDomain::LEVELS.size)
    expect(frames.select { |frame| frame["src"] }).to be_empty
  end

  it "place la ceinture validée et la compétence acquise dans leur case" do
    create(:belt, student: eleve, domain: numeration, level: 2, completed: true, validated_date: Date.current)
    # Deux compétences au niveau : une seule, une fois acquise, validerait
    # d'elle-même la ceinture, et la case montrerait la ceinture.
    acquise = create(:skill, domain: calcul, level: 3, name: "Additionner deux nombres", school:)
    create(:skill, domain: calcul, level: 3, name: "Soustraire deux nombres", school:)
    Result.create!(student: eleve, skill: acquise, kind: "ceinture", status: "completed")

    get student_path(eleve)

    expect(case_de(numeration, 2).at_css(".belt-bar")).to be_present
    expect(case_de(numeration, 3).at_css(".belt-bar")).to be_nil
    expect(case_de(calcul, 3).text).to include("Additionner deux nombres")
    expect(case_de(calcul, 2).text).not_to include("Additionner deux nombres")
  end

  it "ne fait pas grimper les requêtes SQL avec le nombre de domaines" do
    requetes = 0
    compteur = ->(*, payload) { requetes += 1 unless payload[:name] == "SCHEMA" || payload[:cached] }

    get student_path(eleve) # la première requête paie la session et les caches
    ActiveSupport::Notifications.subscribed(compteur, "sql.active_record") { get student_path(eleve) }
    avec_deux = requetes

    create(:domain, grade:, position: 3, name: "Grammaire", special: false)
    create(:domain, grade:, position: 4, name: "Conjugaison", special: false)
    requetes = 0
    ActiveSupport::Notifications.subscribed(compteur, "sql.active_record") { get student_path(eleve) }

    expect(requetes).to eq(avec_deux)
  end

  # La modale du « + » d'une case rappelle de quelle case elle vient.
  it "rappelle le domaine et la ceinture dans la modale de validation" do
    create(:skill, domain: calcul, level: 2, name: "Calculer un double", school:)

    get student_new_validated_wps_path(eleve, params: { domain: calcul.id, level: 2 })

    expect(response.body).to include("Calcul · ceinture jaune")
    expect(response.body).to include("Calculer un double")
  end
end
