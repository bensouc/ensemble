# frozen_string_literal: true

require "rails_helper"
RSpec.describe WorkPlansController, type: :controller do
  let(:user) { create(:user) }
  let(:work_plan) { create(:work_plan, user:) }
  let(:classroom) { create(:classroom, user:) }
  let(:valid_params) { { work_plan_id: work_plan.id } }

  describe "#index" do
    context "when user is not signed in" do
      it "returns a failure response" do
        get :index
        expect(response).not_to be_successful
      end
    end
    context "when user is not signed in" do
      before { sign_in user }
      it "returns a successful response" do
        get :index
        expect(response).to be_successful
      end
    end
  end

  describe "#new" do
    render_views

    context "when user is not signed in" do
      it "returns a failure response" do
        get :new
        expect(response).not_to be_successful
      end
    end
    context "when user is signed in" do
      it "returns a successful response" do
        sign_in(user)
        get :new
        expect(response).to be_successful
        expect(response).to render_template(:new)
      end

      it "range chaque libellé dans la même rangée que son champ" do
        sign_in(user)

        get :new

        expect(response.body.scan("wp-new-label").size).to eq(4)
        expect(response.body).to include("wp-new-grid")
        expect(response.body).to include("wp-new-period")
        %w[work_plan_name work_plan_grade work_plan_student].each do |field|
          expect(response.body).to include(field)
        end
      end
    end
  end

  describe "#show" do
    before { sign_in user }
    it "returns a successful response" do
      # work_plan = WorkPlan.last
      get :show, params: { id: work_plan.id }
      expect(response).to be_successful
    end
  end

  describe "#clone" do
    before { sign_in user }
    context "with no student" do
      it "creates a new one and redirect to It" do
        post :clone, params: valid_params
        expect(response).to redirect_to(work_plan_path(WorkPlan.last))
      end
    end

    context "with two students" do
      before { sign_in user }
      let(:student1) { create(:student, classroom:) }
      let(:student2) { create(:student, classroom:) }

      it "creates a two new wp and redirect to index" do
        valid_params = {
          work_plan_id: work_plan.id,
          "/work_plans/#{work_plan.id}" => {
            students: [student1, student2],
          },
        }
        expect do
          post :clone, params: valid_params
        end.to change(WorkPlan, :count).by(2)
        expect(response).to redirect_to(work_plans_path)
      end
    end
  end

  # L'écran réel visé par la feature : l'éditeur du plan de travail, avec un WPS
  # de type exercice qui n'a pas d'exercice.
  describe "#show avec un exercice manquant" do
    render_views

    it "affiche les CTA Charger et Créer dans l'éditeur" do
      sign_in user
      # `work_plans#show` ne rend que les domaines de la classe du plan de travail
      domain = create(:domain, grade: work_plan.grade)
      skill = create(:skill, school: user.school, domain:)
      create(:challenge, user:, skill:)
      work_plan_domain = create(:work_plan_domain, work_plan:, domain:)
      wps = create(:work_plan_skill, work_plan_domain:, skill:, kind: "exercice", challenge: nil)

      get :show, params: { id: work_plan.id }

      expect(response).to be_successful
      expect(response.body).to include(work_plan_skill_pick_challenge_path(wps))
      expect(response.body).to include(work_plan_skill_create_empty_challenge_path(wps))
    end
  end

  describe "#index, création rapide" do
    render_views

    it "affiche une pastille d'ajout par élève" do
      sign_in user
      grade = create(:grade, school: user.school)
      classroom = create(:classroom, user:, grade:)
      student = create(:student, classroom:)

      get :index

      expect(response.body).to include(student_new_work_plan_modal_path(student))
    end
  end

  # Les deux issues de la modale de création rapide, depuis la liste des plans de
  # travail.
  describe "création rapide pour un élève" do
    let(:grade) { create(:grade, school: user.school) }
    let(:classroom) { create(:classroom, user:, grade:) }
    let(:student) { create(:student, classroom:) }

    before { sign_in user }

    it "crée un plan vierge avec le nom et la période saisis" do
      expect do
        post :create, params: { work_plan: { name: "Semaine 12", student_id: student.id,
                                            grade_id: grade.id, start_date: "16/03/2026",
                                            end_date: "20/03/2026" } }
      end.to change(WorkPlan, :count).by(1)

      created = WorkPlan.last
      expect(created.student).to eq(student)
      expect(created.name).to eq("Semaine 12")
      expect(created.start_date).to eq(Date.new(2026, 3, 16))
      expect(created.work_plan_domains).to be_empty
      expect(response).to redirect_to(work_plan_path(created))
    end

    it "génère un plan auto sur tous les domaines sans qu'on les transmette" do
      domain = create(:domain, grade:, name: "Calcul", special: false)
      skill = create(:skill, school: user.school, domain:, level: 1)
      challenge = create(:challenge, user:, skill:)

      post :auto_new_wp, params: { student_id: student.id,
                                   work_plan: { name: "Auto semaine 12",
                                                start_date: "16/03/2026", end_date: "20/03/2026" } }

      created = WorkPlan.last
      expect(created.name).to eq("Auto semaine 12")
      expect(created.start_date).to eq(Date.new(2026, 3, 16))
      expect(created.work_plan_domains.map(&:domain)).to eq([domain])
      expect(created.work_plan_skills.find_by(skill:).challenge).to eq(challenge)
    end

    it "garde les valeurs par défaut quand le nom et la période ne sont pas transmis" do
      create(:domain, grade:, name: "Calcul", special: false)

      post :auto_new_wp, params: { student_id: student.id }

      created = WorkPlan.last
      expect(created.name).to start_with("AUTO - N°")
      expect(created.start_date).to eq(Time.zone.today.next_occurring(:monday))
    end
  end

  # L'export PDF est un lien simple ouvert dans un onglet : aucun JS entre le clic et
  # le fichier. La visionneuse du navigateur y offre Imprimer et Enregistrer.
  describe "#show au format PDF" do
    render_views

    before { sign_in user }

    it "s'affiche dans l'onglet au lieu de se télécharger" do
      # la génération réelle lance Chrome : hors sujet ici, on ne teste que l'envoi
      allow_any_instance_of(PdfGenerator::WorkPlanPdf).to receive(:generate).and_return("%PDF-1.4")

      get :show, params: { id: work_plan.id }, format: :pdf

      expect(response.headers["Content-Disposition"]).to start_with("inline")
      expect(response.media_type).to eq("application/pdf")
    end

    it "propose l'export par un lien, sans passer par du JS" do
      get :show, params: { id: work_plan.id }

      expect(response.body).to include("/work_plans/#{work_plan.id}.pdf")
      expect(response.body).to include('target="_blank"')
      # c'est ce chemin JS qui annulait le téléchargement en silence
      expect(response.body).not_to include("workplanpdf")
      # le garde : indisponible pendant un enregistrement, confirmation si du
      # contenu n'est pas enregistré
      expect(response.body).to include("pdf-export")
    end
  end

  describe "#evaluation" do
    before { sign_in user }
    it "redirect to the workplan evaluation page" do
      get :show, params: { id: work_plan.id }
      expect(response).to be_successful
    end
  end

  describe "#update" do
    before { sign_in user }
    context "with valid params" do
      let(:new_attributes) do
        { name: "new name",
          student_id: work_plan.student,
          start_date: Time.zone.today, end_date: Time.zone.today + 1 }
      end

      it "updates the work_plan name/ start_date /end_date" do
        put :update, params: { id: work_plan.id, work_plan: new_attributes }
        work_plan.reload
        expect(work_plan.name).to eq("new name")
        expect(work_plan.start_date).to eq(Time.zone.today)
        expect(work_plan.end_date).to eq(Time.zone.today + 1)
      end

      it "redirects to the work_plan" do
        put :update, params: { id: work_plan.id, work_plan: new_attributes }
        expect(response).to redirect_to(work_plan_path(work_plan))
      end
    end
  end

  describe "#auto_gen" do
    before { sign_in user }
    context "with valid params" do
      let(:student) { create(:student, classroom:) }
        let(:domain1) {create(:domain, grade_id: work_plan.grade.id)}
        let(:domain2) {create(:domain, grade_id: work_plan.grade.id)}
      let(:params) do
        {
          "/students/#{student.id}" => {
            domains: ["", domain1.id, domain1.id],
          },
        }
      end
      it "generate a new work_plan, based on the student's actual progression" do
        count = WorkPlan.count
        expect do
          post :auto_new_wp, params: params.merge(student_id: student.id)
        end.to change { WorkPlan.count }.by(2)  # the creation of the work plan initial
        # expect(response).to redirect_to(work_plan_path(WorkPlan.last))
      end
      it "redirects to the Auto Generated WorkPlan " do
        post :auto_new_wp, params: params.merge(student_id: student.id)
        expect(response).to redirect_to(work_plan_path(WorkPlan.last))
      end
    end

    # Toute la chaîne partage l'école de l'enseignant : `Skill.for_school` sert à
    # décider si une ceinture est validée, et un jeu de compétences vide la
    # valide par défaut — ce qui ferait sauter le niveau du domaine généré.
    context "avec des exercices ordonnés sur la compétence" do
      let(:grade) { create(:grade, school: user.school) }
      let(:classroom) { create(:classroom, user:, grade:) }
      let(:student) { create(:student, classroom:) }
      let(:domain) { create(:domain, grade:, name: "Calcul", special: false) }
      let(:skill) { create(:skill, school: user.school, domain:, level: 1) }
      let(:params) { { "/students/#{student.id}" => { domains: ["", domain.id] }, student_id: student.id } }

      def generated_wps
        WorkPlan.last.work_plan_skills.find_by(skill:)
      end

      it "attache le premier exercice, puis le suivant dans l'ordre" do
        first = create(:challenge, user:, skill:)
        second = create(:challenge, user:, skill:)
        second.move_to_bottom

        post :auto_new_wp, params: params
        expect(generated_wps.challenge).to eq(first)

        # exercice raté : le plan suivant donne l'exercice d'après, pas un au hasard
        generated_wps.update!(status: "redo")

        post :auto_new_wp, params: params
        expect(generated_wps.challenge).to eq(second)
      end

      it "laisse le plan de travail sans exercice quand l'élève les a tous eus" do
        only_one = create(:challenge, user:, skill:)

        post :auto_new_wp, params: params
        expect(generated_wps.challenge).to eq(only_one)

        generated_wps.update!(status: "redo")

        expect do
          post :auto_new_wp, params: params
        end.not_to change(Challenge, :count)
        expect(generated_wps.challenge).to be_nil
        expect(generated_wps.kind).to eq("exercice")
      end
    end
  end
end
