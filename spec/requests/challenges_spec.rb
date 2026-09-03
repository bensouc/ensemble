require 'rails_helper'

RSpec.describe "Challenges", type: :request do
  let(:school) { create(:school) }
  let(:user) { create(:user, school:, admin: false) }
  let(:grade) { create(:grade, school:, name: "CE1", grade_level: "CE1") }
  let(:domain) { create(:domain, grade:, name: "Orthographe") }
  let(:skill) { create(:skill, school:, domain:, level: 1) }

  # Ce que le navigateur envoie : le formulaire vit dans un turbo-frame, Turbo
  # accepte un flux mais aussi du HTML.
  let(:turbo_headers) do
    { "Accept" => "text/vnd.turbo-stream.html, text/html, application/xhtml+xml" }
  end

  before { sign_in user }

  describe "POST /challenges" do
    it "crée l'exercice" do
      post challenges_path,
           params: { challenge: { name: "Dictée 1", content: "Écrivez", skill_id: skill.id, for_belt: false } },
           headers: turbo_headers

      expect(skill.challenges.pluck(:name)).to eq(["Dictée 1"])
    end

    # La branche d'échec faisait `redirect_to ..., status: :unprocessable_content` :
    # un 422 au corps vide. Turbo ne suit pas un 422, il cherche quoi rendre et
    # ne trouve rien — le clic de l'enseignant ne produisait donc rien du tout,
    # sans le moindre message.
    it "réaffiche le formulaire avec l'erreur quand le nom est déjà pris pour la compétence" do
      create(:challenge, skill:, user:, name: "Dictée 1")

      post challenges_path,
           params: { challenge: { name: "Dictée 1", content: "<div>Le <strong>hérisson</strong></div>",
                                  skill_id: skill.id, for_belt: false } },
           headers: turbo_headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Nom est déjà utilisé pour cette compétence")
      expect(response.body).to include("Dictée 1")
      # L'énoncé saisi doit revenir dans le formulaire : le perdre à chaque
      # échec de validation ferait retaper l'exercice entier à l'enseignant.
      expect(response.body).to include("hérisson")
      expect(skill.challenges.count).to eq(1)
    end
  end

  describe "PATCH /challenges/:id" do
    let(:challenge) { create(:challenge, skill:, user:, name: "Dictée 2") }

    it "renomme l'exercice" do
      patch challenge_path(challenge), params: { challenge: { name: "Dictée 3" } }, headers: turbo_headers

      expect(challenge.reload.name).to eq("Dictée 3")
    end

    # La branche d'échec redirigeait vers `edit`, ce qui rechargeait l'exercice
    # depuis la base : l'erreur et le nom saisi disparaissaient tous les deux.
    it "réaffiche le formulaire avec l'erreur quand le nouveau nom est déjà pris" do
      create(:challenge, skill:, user:, name: "Dictée 1")

      patch challenge_path(challenge),
            params: { challenge: { name: "Dictée 1", content: "<div>Nouvel énoncé</div>" } },
            headers: turbo_headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Nom est déjà utilisé pour cette compétence")
      expect(response.body).to include("Nouvel énoncé")
      expect(challenge.reload.name).to eq("Dictée 2")
      expect(challenge.content.to_plain_text).not_to include("Nouvel")
    end
  end
end
