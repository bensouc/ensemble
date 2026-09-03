require 'rails_helper'

RSpec.describe "Domains", type: :request do
  let(:school) { create(:school) }
  let(:user) { create(:user, school:, admin: false) }
  # `Grade#name` est unique par école et la factory tire son nom au hasard
  # parmi cinq : deux niveaux nommés explicitement, sinon la suite échoue
  # une fois sur cinq.
  let(:grade) { create(:grade, school:, name: "CE1", grade_level: "CE1") }

  # Ce que le navigateur envoie réellement quand le formulaire est soumis depuis
  # le turbo-frame `new_domain` : Turbo accepte un flux, mais aussi du HTML.
  let(:turbo_headers) do
    { "Accept" => "text/vnd.turbo-stream.html, text/html, application/xhtml+xml",
      "Turbo-Frame" => "new_domain" }
  end

  before { sign_in user }

  describe "POST /domains" do
    it "crée le domaine et renvoie le flux Turbo" do
      post domains_path, params: { domain: { name: "Ceintures d'orthographe", grade_id: grade.id } },
                         headers: turbo_headers

      expect(response).to have_http_status(:success)
      expect(grade.domains.pluck(:name)).to eq(["Ceintures d'orthographe"])
    end

    # La remontée de bug du 03/09/2026 : un nom déjà pris faisait échouer la
    # sauvegarde, et le flux Turbo rendait quand même `_domain` avec un
    # enregistrement sans `id`. L'enseignant recevait un 500.
    it "réaffiche le formulaire avec l'erreur quand le nom est déjà pris pour ce niveau" do
      create(:domain, grade:, name: "Ceintures d'orthographe")

      post domains_path, params: { domain: { name: "Ceintures d'orthographe", grade_id: grade.id } },
                         headers: turbo_headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("est déjà utilisé pour ce niveau")
      expect(response.body).to include('id="new_domain"')
      expect(grade.domains.count).to eq(1)
    end

    it "accepte le même nom dans un autre niveau" do
      other_grade = create(:grade, school:, name: "CM2", grade_level: "CM2")
      create(:domain, grade: other_grade, name: "Ceintures d'orthographe")

      post domains_path, params: { domain: { name: "Ceintures d'orthographe", grade_id: grade.id } },
                         headers: turbo_headers

      expect(response).to have_http_status(:success)
      expect(grade.domains.pluck(:name)).to eq(["Ceintures d'orthographe"])
    end
  end

  describe "PATCH /domains/:id" do
    let(:domain) { create(:domain, grade:, name: "Orthographe") }

    it "renomme le domaine" do
      patch domain_path(domain), params: { domain: { name: "Ceintures d'orthographe", grade_id: grade.id } },
                                 headers: turbo_headers.merge("Turbo-Frame" => "domain_#{domain.id}")

      expect(response).to have_http_status(:success)
      expect(domain.reload.name).to eq("Ceintures d'orthographe")
    end

    # L'ancienne branche d'échec appelait `redirect_to redirect_to`.
    it "réaffiche le formulaire avec l'erreur quand le nouveau nom est déjà pris" do
      create(:domain, grade:, name: "Ceintures d'orthographe")

      patch domain_path(domain), params: { domain: { name: "Ceintures d'orthographe", grade_id: grade.id } },
                                 headers: turbo_headers.merge("Turbo-Frame" => "domain_#{domain.id}")

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("est déjà utilisé pour ce niveau")
      expect(domain.reload.name).to eq("Orthographe")
    end
  end
end
