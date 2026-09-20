# frozen_string_literal: true

require "rails_helper"

# Ce mail est le premier — souvent le seul — que reçoit un enseignant en essai.
# Ce qu'il promet engage : les limites annoncées doivent être celles que
# l'application fait respecter, et les liens doivent mener quelque part.
RSpec.describe DemoMailer do
  let(:user) do
    create(:user, admin: false, demo: true, first_name: " camille ", last_name: "Perrin",
                  email: "camille@ecole.fr")
  end
  let(:mail) { described_class.bienvenue(user) }
  let(:corps) { mail.body.decoded.dup.force_encoding("UTF-8") }
  # Les phrases traversent le balisage (`<strong>28 jours</strong>`) : on lit ce
  # que le destinataire lit.
  let(:texte) { corps.gsub(/<[^>]+>/, " ").gsub(/\s+/, " ").strip }

  it "part à l'enseignant, sous un objet qui le lui dit" do
    expect(mail.to).to eq(["camille@ecole.fr"])
    expect(mail.subject).to eq("Bienvenue sur Ensemble — votre compte de démonstration est ouvert")
  end

  # `ApplicationMailer` poste depuis `bensoucdev@gmail.com` : l'adresse des
  # notifications internes, pas celle sous laquelle se présenter à un client.
  it "part du domaine de l'application" do
    expect(mail.from).to eq(["ne_pas_repondre@app-ensemble.fr"])
    expect(mail[:from].to_s).to include("Ensemble")
  end

  it "accueille l'enseignant par son prénom, quelle que soit sa casse" do
    expect(texte).to include("Bienvenue Camille !")
  end

  # Le chiffre écrit à la main dans le gabarit finirait par mentir : ces deux
  # constantes sont celles que ClassroomPolicy et la vue des élèves appliquent.
  it "annonce les limites que l'application fait respecter" do
    expect(texte).to include("#{User::DEMO_CLASSROOM_LIMIT} classe")
    expect(texte).to include("#{User::DEMO_STUDENT_LIMIT} élèves")
  end

  it "annonce la durée d'essai de l'abonnement" do
    expect(texte).to include("#{Subscription::JOURS_ESSAI} jours d'essai gratuit")
  end

  # Les liens Notion s'écrivent par identifiant nu, et sont déjà réunis dans
  # `TUTO_LINKS` : le mail ne doit pas en recopier un de son côté.
  it "renvoie au sommaire des tutos et aux tutos des quatre premières étapes" do
    expect(corps).to include(ApplicationHelper::TUTO_SOMMAIRE)
    %w[classrooms skills challenges work_plans results].each do |cle|
      expect(corps).to include(ApplicationHelper::TUTO_LINKS.fetch(cle)), "tuto #{cle} absent"
    end
  end

  it "mène au tableau de bord et à la page d'abonnement" do
    expect(corps).to include("/dashboard")
    expect(corps).to include("/subscriptions/on_boarding")
  end
end
