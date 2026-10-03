# frozen_string_literal: true

require "rails_helper"

# config/environments/test.rb coupe la protection CSRF pour toute la suite : sans
# la rallumer ici, aucune spec ne verrait qu'elle manque. C'est ainsi qu'elle a
# manqué en production, l'app n'appelant pas `config.load_defaults`.
RSpec.describe "Protection CSRF", type: :request do
  around do |exemple|
    ActionController::Base.allow_forgery_protection = true
    exemple.run
  ensure
    ActionController::Base.allow_forgery_protection = false
  end

  # Le jeton tel qu'une vraie page le livre au navigateur, lié à la session en cours.
  def jeton_de_la_page(chemin)
    get chemin
    follow_redirect! while response.redirect?
    Nokogiri::HTML(response.body).at_css('meta[name="csrf-token"]')["content"]
  end

  describe "connexion Devise" do
    let(:user) { create(:user, password: "motdepasse123") }
    let(:identifiants) { { user: { email: user.email, password: "motdepasse123" } } }

    # Devise hérite d'ApplicationController : c'est la page la plus exposée.
    it "refuse une connexion postée sans jeton" do
      expect { post user_session_path, params: identifiants }.
        to raise_error(ActionController::InvalidAuthenticityToken)
    end

    it "accepte la connexion avec le jeton du formulaire" do
      jeton = jeton_de_la_page(new_user_session_path)

      post user_session_path, params: identifiants.merge(authenticity_token: jeton)

      expect(response).to have_http_status(:redirect)
      expect(controller.current_user).to eq(user)
    end
  end

  describe "évaluation envoyée par la file du front mobile" do
    let(:user) { create(:user) }
    let(:classroom) { create(:classroom, user:) }
    let(:student) { create(:student, classroom:) }
    let(:work_plan) { create(:work_plan, user:, student:) }
    let(:work_plan_domain) { create(:work_plan_domain, work_plan:) }
    let(:skill) { create(:skill, level: work_plan_domain.level, domain: work_plan_domain.domain) }
    let(:work_plan_skill) do
      create(:work_plan_skill, skill:, kind: "exercice", status: "new", work_plan_domain:)
    end
    let(:url) { work_plan_skill_eval_update_path(work_plan_skill, status: "completed") }

    before { sign_in user }

    it "refuse le geste sans jeton" do
      expect { patch url }.to raise_error(ActionController::InvalidAuthenticityToken)
      expect(work_plan_skill.reload.status).to eq("new")
    end

    # app/javascript/eval_queue.js lit le jeton dans la balise meta et l'envoie
    # en en-tête, comme @rails/request.js et Turbo.
    it "accepte le geste avec le jeton de la page en en-tête" do
      jeton = jeton_de_la_page(root_path)

      patch url, headers: { "X-CSRF-Token" => jeton }

      expect(response).to have_http_status(:ok)
      expect(work_plan_skill.reload.status).to eq("completed")
    end

    # La file traite un 422 comme une session expirée et garde le geste : si
    # Rails changeait de code, elle le prendrait pour un refus définitif.
    it "se solde par un 422 en production" do
      statut = ActionDispatch::ExceptionWrapper.status_code_for_exception("ActionController::InvalidAuthenticityToken")

      expect(statut).to eq(422)
    end
  end

  # Le jeton que Rails pose dans un formulaire ne vaut que pour son `action`. La
  # modale de création rapide envoie son second bouton ailleurs (`formaction`) :
  # elle porte le jeton de session, que Rails accepte partout.
  describe "modale de création rapide d'un plan de travail" do
    let(:user) { create(:user) }
    let(:classroom) { create(:classroom, user:) }
    let(:student) { create(:student, classroom:) }
    let(:plan) do
      { work_plan: { name: "Semaine 41", start_date: "05/10/2026", end_date: "09/10/2026",
                     student_id: student.id, grade_id: classroom.grade_id } }
    end

    before do
      create(:domain, grade: classroom.grade, position: 1, name: "Numération")
      sign_in user
    end

    def jeton_du_formulaire
      get student_new_work_plan_modal_path(student)
      Nokogiri::HTML(response.body).at_css('form.wp-edit-form input[name="authenticity_token"]')["value"]
    end

    it "tourne avec un jeton par formulaire" do
      expect(ActionController::Base.per_form_csrf_tokens).to be(true)
    end

    it "accepte le bouton « Auto », qui part ailleurs que l'action du formulaire" do
      jeton = jeton_du_formulaire

      expect { post student_auto_new_wp_path(student), params: plan.merge(authenticity_token: jeton) }.
        to change(WorkPlan, :count).by(1)
      expect(response).to redirect_to(work_plan_path(WorkPlan.last))
    end

    it "accepte le bouton « Plan vierge »" do
      jeton = jeton_du_formulaire

      expect { post work_plans_path, params: plan.merge(authenticity_token: jeton) }.
        to change(WorkPlan, :count).by(1)
    end
  end

  # Stripe n'a pas de jeton à présenter : c'est la signature qui l'authentifie.
  it "laisse passer le webhook Stripe sans jeton" do
    allow(Stripe::Webhook).to receive(:construct_event).and_raise(JSON::ParserError)

    post "/stripe-webhooks", params: "{}", headers: { "HTTP_STRIPE_SIGNATURE" => "t=1,v1=peu_importe" }

    expect(response).to have_http_status(:bad_request)
  end
end
