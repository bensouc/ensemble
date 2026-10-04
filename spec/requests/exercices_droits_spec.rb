# frozen_string_literal: true

require "rails_helper"

# Les exercices d'une école sont à ses enseignants : c'est l'école de la
# compétence qui les y rattache (`ChallengePolicy`). Le contrôleur sautait
# l'autorisation sur la lecture, l'édition, le clonage et le carrousel : un
# enseignant d'une autre école réécrivait un exercice en donnant son id.
RSpec.describe "Droits sur les exercices", type: :request do
  let(:ecole) { create(:school) }
  let(:enseignant) { create(:user, school: ecole, admin: false) }
  let(:niveau) { create(:grade, school: ecole, name: "CE1", grade_level: "CE1") }
  let(:domaine) { create(:domain, grade: niveau, name: "Orthographe") }
  let(:competence) { create(:skill, school: ecole, domain: domaine, level: 1) }
  let!(:exercice) { create(:challenge, skill: competence, user: enseignant, name: "Dictée du loup") }
  let!(:autre_exercice) { create(:challenge, skill: competence, user: enseignant, name: "Dictée du renard") }

  let(:classe) { create(:classroom, user: enseignant, grade: niveau) }
  let(:eleve) { create(:student, classroom: classe) }
  let(:plan) { create(:work_plan, user: enseignant, grade: niveau, student: eleve) }
  let(:wps) do
    create(:work_plan_skill, work_plan_domain: create(:work_plan_domain, work_plan: plan, domain: domaine, level: 1),
                             skill: competence, kind: "exercice", challenge: exercice)
  end

  let(:intrus) { create(:user, admin: false) }

  let(:turbo_headers) do
    { "Accept" => "text/vnd.turbo-stream.html, text/html, application/xhtml+xml" }
  end

  context "pour un enseignant d'une autre école" do
    before { sign_in intrus }

    it "n'ouvre pas l'exercice" do
      get challenge_path(exercice)

      expect(response).to have_http_status(:redirect)
      expect(flash[:alert]).to be_present
    end

    it "n'ouvre pas son formulaire d'édition" do
      get edit_challenge_path(exercice)

      expect(response).to have_http_status(:redirect)
      expect(flash[:alert]).to be_present
    end

    it "ne le réécrit pas" do
      patch challenge_path(exercice), params: { challenge: { name: "Piraté", content: "Piraté" } }

      expect(exercice.reload.name).to eq("Dictée du loup")
    end

    it "ne remplace pas l'exercice d'un plan de l'autre école par une copie" do
      expect { post work_plan_skill_clone_path(wps, exercice), headers: turbo_headers }.
        not_to change(Challenge, :count)
      expect(wps.reload.challenge).to eq(exercice)
    end

    # Le clone garde la compétence de l'original : copier l'exercice d'une
    # autre école, c'était en écrire un nouveau chez elle.
    it "ne clone pas l'exercice d'une autre école dans son propre plan" do
      son_niveau = create(:grade, school: intrus.school, name: "CE1", grade_level: "CE1")
      son_domaine = create(:domain, grade: son_niveau, name: "Orthographe")
      sa_competence = create(:skill, school: intrus.school, domain: son_domaine, level: 1)
      son_eleve = create(:student, classroom: create(:classroom, user: intrus, grade: son_niveau))
      son_plan = create(:work_plan, user: intrus, grade: son_niveau, student: son_eleve)
      son_wps = create(:work_plan_skill,
                       work_plan_domain: create(:work_plan_domain, work_plan: son_plan, domain: son_domaine, level: 1),
                       skill: sa_competence, kind: "exercice",
                       challenge: create(:challenge, skill: sa_competence, user: intrus))

      expect { post work_plan_skill_clone_path(son_wps, exercice), headers: turbo_headers }.
        not_to change(competence.challenges, :count)
    end

    it "ne liste pas les exercices de la compétence dans le carrousel" do
      post work_plan_skill_display_challenges_path(wps, exercice), headers: turbo_headers

      expect(response.body).not_to include("Dictée du renard")
    end

    # `record.user&.admin?` autorisait n'importe quel enseignant, de n'importe
    # quelle école, à supprimer un exercice écrit par un admin.
    it "ne supprime pas un exercice écrit par un admin" do
      exercice_admin = create(:challenge, skill: competence, user: create(:user, admin: true), name: "Modèle")

      expect { delete challenge_path(exercice_admin) }.not_to change(Challenge, :count)
    end

    it "ne parcourt pas les exercices de l'autre école depuis l'index" do
      son_niveau = create(:grade, school: intrus.school, name: "CE1", grade_level: "CE1")
      create(:classroom, user: intrus, grade: son_niveau)

      get challenges_path, params: { "/challenges" => { grade: niveau.id, domain: domaine.id, level: 1 } }

      expect(response.body).not_to include("Dictée du loup")
    end
  end

  context "pour l'enseignant de l'école" do
    before { sign_in enseignant }

    it "ouvre, édite et réécrit l'exercice" do
      get challenge_path(exercice)
      expect(response).to have_http_status(:ok)

      get edit_challenge_path(exercice)
      expect(response).to have_http_status(:ok)

      patch challenge_path(exercice), params: { challenge: { name: "Dictée du loup (2)" } }, headers: turbo_headers
      expect(exercice.reload.name).to eq("Dictée du loup (2)")
    end

    # Changer un exercice de compétence passe par `transfer`, qui garde le
    # domaine et refuse un exercice déjà utilisé. `update` acceptait `skill_id`
    # et `for_belt` sans rien vérifier — jusqu'à ranger l'exercice sous la
    # compétence d'une autre école.
    it "ne change pas de compétence ni de liste par la mise à jour" do
      competence_etrangere = create(:skill)

      patch challenge_path(exercice),
            params: { challenge: { name: "Dictée du loup", skill_id: competence_etrangere.id, for_belt: true } },
            headers: turbo_headers

      exercice.reload
      expect(exercice.skill).to eq(competence)
      expect(exercice.for_belt).to be(false)
    end

    it "clone l'exercice d'un plan de son école" do
      expect { post work_plan_skill_clone_path(wps, exercice), headers: turbo_headers }.
        to change(competence.challenges, :count).by(1)
      expect(wps.reload.challenge).not_to eq(exercice)
    end

    it "ouvre le carrousel de la compétence" do
      post work_plan_skill_display_challenges_path(wps, exercice), headers: turbo_headers

      expect(response.body).to include("Dictée du renard")
    end

    it "parcourt les exercices de son école depuis l'index" do
      classe

      get challenges_path, params: { "/challenges" => { grade: niveau.id, domain: domaine.id, level: 1 } }

      expect(response.body).to include("Dictée du loup")
    end
  end

  # L'admin intervient dans toutes les écoles : chaque règle commence par
  # `user.admin? ||`. Sans ce contexte, une règle qui l'oublierait ne ferait
  # rougir aucune spec.
  context "pour un admin d'une autre école" do
    let(:admin) { create(:user, admin: true) }

    before { sign_in admin }

    it "ouvre, réécrit et clone l'exercice, et ouvre le carrousel" do
      get challenge_path(exercice)
      expect(response).to have_http_status(:ok)

      get edit_challenge_path(exercice)
      expect(response).to have_http_status(:ok)

      patch challenge_path(exercice), params: { challenge: { name: "Dictée du loup (2)" } }, headers: turbo_headers
      expect(exercice.reload.name).to eq("Dictée du loup (2)")

      post work_plan_skill_display_challenges_path(wps, exercice), headers: turbo_headers
      expect(response.body).to include("Dictée du renard")

      expect { post work_plan_skill_clone_path(wps, exercice), headers: turbo_headers }.
        to change(competence.challenges, :count).by(1)
    end

    it "parcourt les exercices de l'école depuis l'index" do
      create(:classroom, user: admin)

      get challenges_path, params: { "/challenges" => { grade: niveau.id, domain: domaine.id, level: 1 } }

      expect(response.body).to include("Dictée du loup")
    end

    it "supprime un exercice que rien n'utilise" do
      expect { delete challenge_path(autre_exercice) }.to change(Challenge, :count).by(-1)
    end
  end

  # Les exercices d'une école sont à TOUS ses enseignants, pas à leur seul
  # auteur : c'est le partage au sein du groupe scolaire (`School`). Les
  # contextes précédents ne faisaient agir que l'auteur.
  context "pour un collègue de l'école qui n'en est pas l'auteur" do
    let(:collegue) { create(:user, school: ecole, admin: false) }

    before { sign_in collegue }

    it "ouvre, réécrit, duplique et range l'exercice" do
      get challenge_path(exercice)
      expect(response).to have_http_status(:ok)

      get edit_challenge_path(exercice)
      expect(response).to have_http_status(:ok)

      patch challenge_path(exercice), params: { challenge: { name: "Dictée du loup (2)" } }, headers: turbo_headers
      expect(exercice.reload.name).to eq("Dictée du loup (2)")

      expect { post duplicate_challenge_path(exercice), headers: turbo_headers }.
        to change(competence.challenges, :count).by(1)

      patch move_challenge_path(autre_exercice), params: { direction: "up" }, headers: turbo_headers
      expect(autre_exercice.reload.position).to eq(1)
    end

    it "parcourt les exercices de l'école depuis l'index" do
      create(:classroom, user: collegue, grade: niveau)

      get challenges_path, params: { "/challenges" => { grade: niveau.id, domain: domaine.id, level: 1 } }

      expect(response.body).to include("Dictée du loup")
    end

    it "prend l'exercice d'un autre dans son plan, ouvre le carrousel et le clone" do
      son_eleve = create(:student, classroom: create(:classroom, user: collegue, grade: niveau))
      son_plan = create(:work_plan, user: collegue, grade: niveau, student: son_eleve)
      son_wps = create(:work_plan_skill,
                       work_plan_domain: create(:work_plan_domain, work_plan: son_plan, domain: domaine, level: 1),
                       skill: competence, kind: "exercice", challenge: autre_exercice)

      patch work_plan_skill_path(son_wps), params: { work_plan_skill: { challenge_id: exercice.id } },
                                           headers: turbo_headers
      expect(son_wps.reload.challenge).to eq(exercice)

      post work_plan_skill_display_challenges_path(son_wps, exercice), headers: turbo_headers
      expect(response.body).to include("Dictée du renard")

      expect { post work_plan_skill_clone_path(son_wps, exercice), headers: turbo_headers }.
        to change(competence.challenges, :count).by(1)
    end

    it "supprime l'exercice d'un autre que rien n'utilise" do
      expect { delete challenge_path(autre_exercice) }.to change(Challenge, :count).by(-1)
    end
  end
end
