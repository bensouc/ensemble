# frozen_string_literal: true

require "rails_helper"

# Le portail client de Stripe ne sait pas modifier un abonnement sur facture : le
# responsable ne peut qu'y résilier. Sa demande passe donc par nous.
RSpec.describe "Demande de modification d'abonnement", type: :request do
  let(:school) { create(:school, name: "Groupe Alain-Fournier", email: "compta@exemple.fr") }
  let(:responsable) { create(:user, admin: false, demo: false, email: "directrice@exemple.fr") }
  let(:collegue) { create(:user, admin: false, demo: false) }

  def abonner(collection_method: "send_invoice", quantity: 8)
    Subscription.create!(school:, collection_method:, quantity:, status: "active", rythm: "Annuel",
                         stripe_subscription_id: "sub_test",
                         current_period_start: Date.new(2026, 9, 1),
                         current_period_end: Date.new(2027, 8, 31))
  end

  before do
    ActionMailer::Base.deliveries.clear
    school.add_teacher(responsable, true)
    school.add_teacher(collegue)
  end

  describe "GET le formulaire" do
    before { abonner }

    it "s'ouvre pour le responsable, prérempli de la quantité payée" do
      sign_in responsable.reload
      get subscription_change_request_path

      expect(response).to have_http_status(:ok)
      choisi = Nokogiri::HTML(response.body).css("#subscription_change_classes option[selected]").first
      expect(choisi["value"]).to eq("8")
    end

    # Le responsable décide en euros, pas en nombre de classes : sans les deux
    # tarifs il valide un changement dont il ne connaît pas le prix.
    it "affiche le tarif actuel et le nouveau" do
      sign_in responsable.reload
      get subscription_change_request_path
      page = Nokogiri::HTML(response.body)

      expect(page.css("#tarif_actuel").first["value"]).to eq("376 €")
      expect(page.css("#nouveau_tarif").first["value"]).to eq("376 €")
    end

    # La facturation du groupe est l'affaire du responsable : sans ça, n'importe
    # quel enseignant peut nous demander de changer la quantité payée.
    it "est fermé à un enseignant qui n'est pas responsable" do
      sign_in collegue.reload
      get subscription_change_request_path

      expect(response).to have_http_status(:redirect)
      expect(flash[:alert]).to be_present
    end
  end

  it "renvoie souscrire une école qui n'a pas d'abonnement" do
    sign_in responsable.reload
    get subscription_change_request_path

    expect(response).to redirect_to(new_subscription_path)
    expect(flash[:alert]).to include("Souscrivez un abonnement")
  end

  describe "POST la demande" do
    before do
      abonner
      sign_in responsable.reload
    end

    def demander(classes, message = "Une classe de plus à la rentrée.")
      post create_subscription_change_request_path,
           params: { subscription_change: { classes:, message: } }
    end

    # Les phrases des gabarits sont coupées par des retours à la ligne : sans
    # aplatir les espaces, une assertion sur une phrase entière échoue toujours.
    def corps_de(objet)
      mail = ActionMailer::Base.deliveries.find { |m| m.subject.include?(objet) }
      mail.body.encoded.gsub(/\s+/, " ")
    end

    it "confirme au responsable et le ramène sur sa page École" do
      demander(9)

      expect(response).to redirect_to(school_path(school))
      expect(flash[:notice]).to include("Votre demande nous est parvenue")
    end

    it "envoie la notification interne et l'accusé à l'école" do
      expect { demander(9) }.to change { ActionMailer::Base.deliveries.count }.by(2)
    end

    # C'est l'avant/après qui rend la demande actionnable : la quantité payée et
    # le nombre de classes créées divergent, c'est même ce qui bloque la création.
    it "dit l'avant, l'après et les identifiants Stripe dans la notification interne" do
      demander(9)
      interne = ActionMailer::Base.deliveries.find { |m| m.subject.include?("Modification d'abonnement") }

      expect(interne.to).to eq(["bensoucdev@gmail.com"])
      expect(interne.subject).to include("Groupe Alain-Fournier")
      corps = corps_de("Modification d'abonnement")
      expect(corps).to include("8 classes")
      expect(corps).to include("9 classes")
      expect(corps).to include("sub_test")
      expect(corps).to include("Une classe de plus à la rentrée")
    end

    # L'adresse de facturation est celle du client Stripe, souvent personnelle là
    # où le service comptable attend la facture. La nommer donne à l'école
    # l'occasion de la corriger avant l'émission.
    it "adresse l'accusé au demandeur ET à l'adresse de facturation, qu'il nomme" do
      demander(9)
      accuse = ActionMailer::Base.deliveries.find { |m| m.subject.include?("Votre demande") }

      expect(accuse.to).to contain_exactly("directrice@exemple.fr", "compta@exemple.fr")
      expect(corps_de("Votre demande")).to include("compta@exemple.fr")
    end

    # Stripe émet une facture de prorata sur une hausse, un avoir sur une baisse :
    # promettre « une facture » dans les deux sens était faux pour une école qui
    # réduit son nombre de classes.
    describe "ce que l'accusé annonce" do
      def annonce(classes)
        demander(classes)
        corps_de("Votre demande")
      end

      it "annonce une facture sur une hausse" do
        expect(annonce(9)).to include("facture de modification")
      end

      it "annonce un avoir sur une baisse" do
        corps = annonce(6)
        expect(corps).to include("avoir")
        expect(corps).not_to include("facture de modification")
      end

      # Le responsable peut renvoyer sa quantité actuelle pour poser une question
      # dans le champ libre : il n'y a alors ni facture ni avoir à annoncer.
      it "n'annonce rien à quantité égale" do
        corps = annonce(8)
        expect(corps).to include("rien à modifier ni à facturer")
        expect(corps).not_to include("avoir")
      end
    end

    it "refuse une quantité nulle sans rien envoyer" do
      expect { demander(0) }.not_to change { ActionMailer::Base.deliveries.count }
      expect(response).to have_http_status(:unprocessable_content)
      expect(flash[:alert]).to include("au moins 1")
    end

    # `mail` lève sans destinataire : une école ancienne peut n'avoir aucun email,
    # et ce serait une 500 sur une demande par ailleurs bien reçue.
    it "transmet la demande même sans adresse de facturation" do
      school.update_column(:email, nil)

      expect { demander(9) }.to change { ActionMailer::Base.deliveries.count }.by(2)
      accuse = ActionMailer::Base.deliveries.find { |m| m.subject.include?("Votre demande") }
      expect(accuse.to).to eq(["directrice@exemple.fr"])
    end
  end
end
