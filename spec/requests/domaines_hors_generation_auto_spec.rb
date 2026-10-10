# frozen_string_literal: true

require "rails_helper"

# Un professeur sort un domaine de la génération automatique de ses plans de
# travail depuis la page des domaines. Le domaine reste proposé dans les deux
# modales de génération, décoché ; et c'est SA préférence : un collègue de la
# même école génère toujours sur ce domaine.
RSpec.describe "Domaines hors génération automatique", type: :request do
  let(:school) { create(:school) }
  let(:enseignant) { create(:user, school:, admin: false) }
  let(:grade) { create(:grade, school:, name: "CE1", grade_level: "CE1") }
  let(:classroom) { create(:classroom, user: enseignant, grade:) }
  let(:eleve) { create(:student, classroom:) }
  # Noms explicites : la factory en tire un au hasard, et deux domaines du même
  # niveau ne peuvent pas le partager.
  let!(:numeration) { create(:domain, grade:, position: 1, name: "Numération") }
  let!(:conjugaison) { create(:domain, grade:, position: 2, name: "Conjugaison") }

  # La case d'un domaine, cochée ou non, telle que la modale la rend.
  def case_cochee?(body, domain)
    input = Nokogiri::HTML(body).css("input[type=checkbox][value='#{domain.id}']").first
    raise "Pas de case pour #{domain.name}" unless input

    input.key?("checked")
  end

  before { sign_in enseignant }

  describe "la bascule sur la page des domaines" do
    it "sort le domaine de la génération, puis l'y remet" do
      expect { post domain_auto_gen_exclusion_path(conjugaison), as: :turbo_stream }.
        to change { enseignant.auto_gen_exclusions.count }.from(0).to(1)
      expect(response.body).to include("domain-auto-toggle--off")

      expect { delete domain_auto_gen_exclusion_path(conjugaison), as: :turbo_stream }.
        to change { enseignant.auto_gen_exclusions.count }.from(1).to(0)
      expect(response.body).not_to include("domain-auto-toggle--off")
    end

    it "ne crée pas de doublon sur un second clic" do
      2.times { post domain_auto_gen_exclusion_path(conjugaison), as: :turbo_stream }

      expect(enseignant.auto_gen_exclusions.count).to eq(1)
    end

    it "refuse un domaine d'une autre école" do
      ailleurs = create(:domain, grade: create(:grade, name: "CM2", grade_level: "CM2"), name: "Calcul")

      expect { post domain_auto_gen_exclusion_path(ailleurs), as: :turbo_stream }.
        not_to change(AutoGenExclusion, :count)
    end

    it "affiche l'état de chaque domaine sur la page des domaines" do
      enseignant.auto_gen_exclusions.create!(domain: conjugaison)

      get grade_domains_path(grade)

      page = Nokogiri::HTML(response.body)
      expect(page.css("#domain_#{conjugaison.id} .domain-auto-toggle--off")).to be_present
      expect(page.css("#domain_#{numeration.id} .domain-auto-toggle--off")).to be_empty
    end
  end

  describe "les modales de génération" do
    before { enseignant.auto_gen_exclusions.create!(domain: conjugaison) }

    it "proposent le domaine exclu, décoché, dans la modale des résultats de classe" do
      get student_auto_gen_modal_path(eleve)

      expect(case_cochee?(response.body, numeration)).to be(true)
      expect(case_cochee?(response.body, conjugaison)).to be(false)
    end

    it "proposent le domaine exclu, décoché, dans la modale « Ajouter » de l'index" do
      get student_new_work_plan_modal_path(eleve)

      expect(case_cochee?(response.body, numeration)).to be(true)
      expect(case_cochee?(response.body, conjugaison)).to be(false)
      # Repliée et inerte tant que « Auto » n'est pas choisi : un plan vierge
      # n'envoie aucun domaine.
      fieldset = Nokogiri::HTML(response.body).css("fieldset.wp-new-domains").first
      expect(fieldset.key?("hidden") && fieldset.key?("disabled")).to be(true)
    end

    # Les deux ouvrent le plan dans un nouvel onglet et se masquent à l'envoi :
    # la modale de la fiche élève restait ouverte derrière.
    it "ouvrent le plan dans un nouvel onglet et se referment à l'envoi" do
      [student_auto_gen_modal_path(eleve), student_new_work_plan_modal_path(eleve)].each do |modale|
        get modale

        form = Nokogiri::HTML(response.body).css("form").first
        expect(form["target"]).to eq("_blank")
        expect(form["data-action"]).to include("submit->modals#emptyModal")
      end
    end

    it "passent par la modale commune depuis la fiche de l'élève" do
      get student_path(eleve)

      expect(response.body).to include(student_auto_gen_modal_path(eleve))
      expect(response.body).not_to include("staticBackdrop")
    end

    it "laissent un collègue de l'école générer sur ce domaine" do
      collegue = create(:user, school:, admin: false)
      classroom.update!(user: collegue)
      sign_in collegue

      get student_auto_gen_modal_path(eleve)

      expect(case_cochee?(response.body, conjugaison)).to be(true)
    end
  end

  describe "la génération" do
    before { enseignant.auto_gen_exclusions.create!(domain: conjugaison) }

    it "génère le domaine exclu quand le professeur le coche quand même" do
      post student_auto_new_wp_path(eleve), params: { student: { domains: ["", numeration.id, conjugaison.id] } }

      expect(WorkPlan.last.work_plan_domains.map(&:domain)).to contain_exactly(numeration, conjugaison)
    end

    it "sans domaine transmis, laisse de côté le domaine exclu" do
      post student_auto_new_wp_path(eleve)

      expect(WorkPlan.last.work_plan_domains.map(&:domain)).to contain_exactly(numeration)
    end
  end
end
