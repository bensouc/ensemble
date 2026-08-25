# frozen_string_literal: true

require "rails_helper"

# Un message unique couvrait cinq situations et ne donnait la bonne consigne que
# dans l'une d'elles. Chaque cause a désormais la sienne.
RSpec.describe ClassroomsController, type: :controller do
  render_views

  let(:school) { create(:school, stripe_customer_id: "cus_test") }
  let(:responsable) { create(:user, admin: false, demo: false, first_name: "Claire") }
  let(:collegue) { create(:user, admin: false, demo: false) }

  def subscribe(status: "active", quantity: 2)
    Subscription.create!(school:, status:, quantity:, rythm: "Annuel",
                         current_period_start: Date.new(2026, 9, 1),
                         current_period_end: Date.new(2027, 8, 31))
  end

  def zone_for(user)
    sign_in(user.reload)
    get :index
    Nokogiri::HTML(response.body).css(".classroom-creation").text.gsub(/\s+/, " ").strip
  end

  before do
    school.add_teacher(responsable, true)
    school.add_teacher(collegue)
  end

  describe "quota atteint" do
    before do
      subscribe(quantity: 2)
      2.times { create(:classroom, user: collegue) }
    end

    it "donne au responsable l'action qu'il peut faire lui-même" do
      zone = zone_for(responsable)
      expect(zone).to include("Votre abonnement couvre 2 classes, toutes utilisées")
      expect(zone).to include("Ajouter une classe à mon abonnement")
      expect(zone).not_to include("Demandez à")
    end

    it "donne au collègue le nom de la personne à qui s'adresser" do
      zone = zone_for(collegue)
      expect(zone).to include("L'abonnement du groupe couvre 2 classes, toutes utilisées")
      expect(zone).to include("Demandez à Claire d'en ajouter une")
      expect(zone).not_to include("Ajouter une classe à mon abonnement")
    end

    # « Les <n> classes … sont toutes utilisées » donnait « Les 1 classes ».
    it "accorde le message quand l'abonnement ne couvre qu'une classe" do
      school.subscription.update!(quantity: 1)
      expect(zone_for(collegue)).to include("couvre 1 classe, déjà utilisée")
    end
  end

  describe "abonnement résilié" do
    before { subscribe(status: "canceled") }

    # C'est le cas qui recevait « demandez de modifier les quantités ».
    it "dit que l'abonnement est en cause, pas la quantité" do
      zone = zone_for(responsable)
      expect(zone).to include("votre abonnement est annulé")
      expect(zone).to include("Reprendre mon abonnement")
      expect(zone).not_to match(/quantité/i)
    end

    it "renvoie le collègue vers le responsable" do
      expect(zone_for(collegue)).to include("Prévenez Claire")
    end
  end

  describe "aucun abonnement" do
    it "propose la souscription au responsable" do
      zone = zone_for(responsable)
      expect(zone).to include("n'a pas encore d'abonnement")
      expect(zone).to include("Souscrire un abonnement")
    end

    it "renvoie le collègue vers le responsable" do
      expect(zone_for(collegue)).to include("Demandez à Claire d'en souscrire un")
    end
  end

  describe "plusieurs responsables" do
    # N'importe lequel peut agir : « ou », pas une énumération sèche.
    it "les relie par « ou »" do
      marc = create(:user, admin: false, demo: false, first_name: "Marc")
      school.add_teacher(marc, true)
      subscribe(quantity: 1)
      create(:classroom, user: collegue)
      expect(zone_for(collegue)).to include("Demandez à Claire ou Marc d'en ajouter une")
    end

    it "n'énumère qu'au dernier rang au-delà de deux" do
      %w[Marc Sophie].each { |prenom| school.add_teacher(create(:user, admin: false, first_name: prenom), true) }
      subscribe(quantity: 1)
      create(:classroom, user: collegue)
      expect(zone_for(collegue)).to include("Claire, Marc ou Sophie")
    end

    it "donne l'action à chacun d'eux, pas le nom des autres" do
      marc = create(:user, admin: false, demo: false, first_name: "Marc")
      school.add_teacher(marc, true)
      subscribe(quantity: 1)
      create(:classroom, user: collegue)
      zone = zone_for(marc)
      expect(zone).to include("Ajouter une classe à mon abonnement")
      expect(zone).not_to include("Demandez à")
    end
  end

  describe "cas limites" do
    # Le portail Stripe lève une erreur sans client : mieux vaut ne pas l'offrir.
    it "n'offre pas le portail à une école sans client Stripe" do
      school.update!(stripe_customer_id: nil)
      subscribe(status: "canceled")
      zone = zone_for(responsable)
      expect(zone).not_to include("Reprendre mon abonnement")
      expect(zone).to include("Souscrire un abonnement")
    end

    it "reste lisible dans une école sans responsable" do
      responsable.school_role.update!(super_teacher: false)
      expect(zone_for(collegue)).to include("Demandez à votre responsable de groupe")
    end

    # `capitalize` sans `strip` affichait « (Benoît ) ».
    it "ne traîne pas les espaces saisis dans le prénom" do
      responsable.update_column(:first_name, "Benoît ")
      subscribe(quantity: 1)
      create(:classroom, user: collegue)
      expect(zone_for(collegue)).to include("Demandez à Benoît d'en ajouter une")
    end

    it "garde le compte démo sur son propre message" do
      demo = create(:user, admin: false, demo: true)
      create(:classroom, user: demo)
      zone = zone_for(demo)
      expect(zone).to include("Compte de démonstration")
      expect(zone).to include("Abonnez-vous")
    end
  end
end
