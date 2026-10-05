# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Manipule, le suivi d'une classe" do
  # L'option Manipule s'ouvre compte par compte ; sans elle, redirection.
  let(:enseignante) { create(:user, admin: false, manipule: true) }
  let(:niveau) { create(:grade, school: enseignante.school) }
  let(:domaine) { create(:domain, grade: niveau) }
  let(:classe) { create(:classroom, user: enseignante, grade: niveau) }
  let!(:sam) { create(:student, classroom: classe, first_name: "Sam") }
  let!(:lila) { create(:student, classroom: classe, first_name: "Lila") }

  let(:competence) do
    create(:skill, domain: domaine, school: enseignante.school, level: 1, name: "Recherche d'une partie")
  end

  before { sign_in enseignante }

  describe "désigner une compétence" do
    before { create_list(:manipule_problem, 3, skill: competence) }

    it "désigne pour un seul élève" do
      post manipule_suivi_affecter_path(classe), params: { skill_id: competence.id, student_id: sam.id }

      expect(Manipule::Assignment.courante(sam).skill).to eq(competence)
      expect(Manipule::Assignment.courante(lila)).to be_nil
    end

    it "désigne pour toute la classe d'un coup" do
      post manipule_suivi_affecter_path(classe), params: { skill_id: competence.id }

      expect(Manipule::Assignment.courante(sam).skill).to eq(competence)
      expect(Manipule::Assignment.courante(lila).skill).to eq(competence)
    end

    it "remplace l'affectation précédente au lieu d'en empiler une seconde" do
      autre = create(:skill, domain: domaine, school: enseignante.school, level: 1, name: "Recherche d'un tout")
      create(:manipule_problem, skill: autre)

      post manipule_suivi_affecter_path(classe), params: { skill_id: competence.id, student_id: sam.id }
      post manipule_suivi_affecter_path(classe), params: { skill_id: autre.id, student_id: sam.id }

      expect(Manipule::Assignment.active.where(student: sam).count).to eq(1)
      expect(Manipule::Assignment.courante(sam).skill).to eq(autre)
    end
  end

  describe "la page de suivi" do
    # Désigner une compétence sans problème en circulation mènerait l'élève à un
    # écran vide, sans qu'elle puisse comprendre pourquoi.
    it "ne propose que les compétences qui ont des problèmes en circulation" do
      vide = create(:skill, domain: domaine, school: enseignante.school, level: 1, name: "Compétence vide")
      create(:manipule_problem, skill: competence)
      create(:manipule_problem, :brouillon, skill: vide)

      get manipule_suivi_classe_path(classe)

      expect(assigns(:competences)).to include(competence)
      expect(assigns(:competences)).not_to include(vide)
    end

    it "prévient quand aucune compétence n'est prête" do
      get manipule_suivi_classe_path(classe)

      expect(response.body).to include("Aucune compétence de ce niveau")
    end

    it "affiche l'adresse des élèves" do
      get manipule_suivi_classe_path(classe)

      expect(response.body).to include(Manipule::ClassroomToken.pour!(classe).token)
    end

    it "sépare les justes, les faux et les passés dans la dernière séance" do
      create_list(:manipule_problem, 3, skill: competence)
      serie = Manipule::Practice.commencer!(student: sam, skill: competence)
      serie.attempts.first.repondre_par_choix!(serie.attempts.first.problem.choices.find(&:correct?))
      serie.attempts.second.passer!

      get manipule_suivi_classe_path(classe)

      expect(response.body).to include("1 juste", "0 faux", "1 passé")
    end

    it "remonte les problèmes sur lesquels la classe bute" do
      create_list(:manipule_problem, 2, skill: competence)
      serie = Manipule::Practice.commencer!(student: sam, skill: competence)
      coince = serie.attempts.first
      coince.repondre_par_choix!(coince.problem.choices.reject(&:correct?).first)

      get manipule_suivi_classe_path(classe)

      expect(assigns(:qui_coince).map(&:first)).to include(coince.problem)
    end
  end

  describe "le renouvellement de l'adresse" do
    it "ferme l'ancienne" do
      ancien = Manipule::ClassroomToken.pour!(classe).token

      post manipule_suivi_jeton_path(classe)

      expect(Manipule::ClassroomToken.pour!(classe).reload.token).not_to eq(ancien)
    end
  end

  describe "le cloisonnement" do
    it "n'ouvre pas la classe d'un autre enseignant" do
      ailleurs = create(:classroom, user: create(:user, admin: false))

      get manipule_suivi_classe_path(ailleurs)

      expect(response).to have_http_status(:redirect)
      expect(flash[:alert]).to be_present
    end

    it "ne désigne rien dans la classe d'un autre" do
      ailleurs = create(:classroom, user: create(:user, admin: false))
      eleve_ailleurs = create(:student, classroom: ailleurs)

      post manipule_suivi_affecter_path(ailleurs), params: { skill_id: competence.id }

      expect(Manipule::Assignment.courante(eleve_ailleurs)).to be_nil
    end
  end
end
