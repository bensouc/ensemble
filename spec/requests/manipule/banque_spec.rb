# frozen_string_literal: true

require "rails_helper"
require "csv"

RSpec.describe "Manipule, la banque côté enseignante" do
  # La factory :user fabrique un ADMIN. Un admin voit tout, et les tests de
  # cloisonnement ne testeraient alors rien du tout.
  # `manipule: true` : l'option s'ouvre compte par compte, et sans elle ces
  # pages redirigent avant même d'être atteintes.
  let(:enseignante) { create(:user, admin: false, manipule: true) }
  let(:competence) do
    domaine = create(:domain, grade: create(:grade, school: enseignante.school))
    create(:skill, domain: domaine, school: enseignante.school, level: 1, name: "Recherche d'une partie")
  end

  def fichier_csv(lignes, separateur: ",")
    chemin = Rails.root.join("tmp/import_test.csv")
    CSV.open(chemin, "w", col_sep: separateur) { |csv| lignes.each { |ligne| csv << ligne } }
    Rack::Test::UploadedFile.new(chemin, "text/csv", original_filename: "problemes.csv")
  end

  def en_tete
    ["Énoncé", "Question", "Bonne réponse", "Mauvaise réponse 1", "Mauvaise réponse 2"]
  end

  def ligne(n = 1)
    ["Il y a #{n + 7} pommes. Sam en cueille #{n}.", "Combien reste-t-il de pommes ?",
     "7 pommes", "#{n + 7} pommes", "#{n} pommes"]
  end

  before { sign_in enseignante }

  describe "l'import" do
    it "crée les problèmes en brouillon, pas en circulation" do
      post manipule_banque_importer_path(competence), params: { fichier: fichier_csv([en_tete, ligne(1), ligne(2)]) }

      expect(Manipule::Problem.count).to eq(2)
      expect(Manipule::Problem.pluck(:published).uniq).to eq([false])
      expect(flash[:notice]).to include("2 problèmes importés")
    end

    it "donne trois réponses à chaque problème, dont une seule juste" do
      post manipule_banque_importer_path(competence), params: { fichier: fichier_csv([en_tete, ligne(1)]) }

      probleme = Manipule::Problem.last
      expect(probleme.choices.count).to eq(3)
      expect(probleme.choices.count(&:correct?)).to eq(1)
    end

    # Un tableur français exporte en CSV avec des points-virgules : personne ne
    # va expliquer ça à une enseignante.
    it "lit aussi un fichier séparé par des points-virgules" do
      post manipule_banque_importer_path(competence),
           params: { fichier: fichier_csv([en_tete, ligne(1)], separateur: ";") }

      expect(Manipule::Problem.count).to eq(1)
    end

    it "accepte des titres sans accents et dans un autre ordre" do
      entete = ["Question", "Mauvaise reponse 2", "Enonce", "Bonne reponse", "Mauvaise reponse 1"]
      donnees = ["Combien ?", "1 pomme", "Il y a 8 pommes.", "7 pommes", "8 pommes"]

      post manipule_banque_importer_path(competence), params: { fichier: fichier_csv([entete, donnees]) }

      expect(Manipule::Problem.last.statement).to eq("Il y a 8 pommes.")
      expect(Manipule::Problem.last.choices.find(&:correct?).label).to eq("7 pommes")
    end

    # Importer la moitié d'un fichier laisserait l'enseignante deviner ce qui
    # est passé, et réimporter créerait des doublons.
    it "n'importe rien du tout quand une seule ligne est fautive" do
      mauvaise = ["", "Combien ?", "7 pommes", "8 pommes", "1 pomme"]

      post manipule_banque_importer_path(competence),
           params: { fichier: fichier_csv([en_tete, ligne(1), mauvaise, ligne(3)]) }

      expect(Manipule::Problem.count).to eq(0)
      expect(response.body).to include("Ligne 3")
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "dit quelles colonnes manquent" do
      post manipule_banque_importer_path(competence),
           params: { fichier: fichier_csv([%w[Enonce Question], ["Un énoncé", "Une question"]]) }

      expect(response.body).to include("Colonnes manquantes")
      expect(Manipule::Problem.count).to eq(0)
    end

    it "refuse un format qu'il ne sait pas lire" do
      chemin = Rails.root.join("tmp/import_test.txt")
      File.write(chemin, "n'importe quoi")
      fichier = Rack::Test::UploadedFile.new(chemin, "text/plain", original_filename: "notes.txt")

      post manipule_banque_importer_path(competence), params: { fichier: }

      expect(response.body).to include("Format non reconnu")
    end

    it "ignore une ligne vide en fin de fichier" do
      post manipule_banque_importer_path(competence),
           params: { fichier: fichier_csv([en_tete, ligne(1), ["", "", "", "", ""]]) }

      expect(Manipule::Problem.count).to eq(1)
    end
  end

  describe "la mise en circulation" do
    before { post manipule_banque_importer_path(competence), params: { fichier: fichier_csv([en_tete, ligne(1), ligne(2)]) } }

    it "publie tous les brouillons d'un coup" do
      post manipule_banque_publier_path(competence)

      expect(Manipule::Problem.pluck(:published).uniq).to eq([true])
    end

    it "bascule un problème seul, dans les deux sens" do
      probleme = Manipule::Problem.first

      patch manipule_probleme_circulation_path(probleme)
      expect(probleme.reload.published).to be true

      patch manipule_probleme_circulation_path(probleme)
      expect(probleme.reload.published).to be false
    end
  end

  describe "le cloisonnement entre écoles" do
    it "n'ouvre pas la compétence d'une autre école" do
      ailleurs = create(:skill, domain: create(:domain, grade: create(:grade, school: create(:school))),
                                school: create(:school), level: 1)

      # `ApplicationController` rattrape Pundit : on est renvoyé avec une
      # alerte, aucune exception ne remonte jusqu'ici.
      get manipule_banque_competence_path(ailleurs)

      expect(response).to have_http_status(:redirect)
      expect(flash[:alert]).to be_present
    end

    it "ne liste que les problèmes de son école" do
      post manipule_banque_importer_path(competence), params: { fichier: fichier_csv([en_tete, ligne(1)]) }
      autre_ecole = create(:school)
      autre_competence = create(:skill, domain: create(:domain, grade: create(:grade, school: autre_ecole)),
                                        school: autre_ecole, level: 1)
      create(:manipule_problem, skill: autre_competence)

      get manipule_banque_path

      expect(assigns(:problemes).map(&:skill).uniq).to eq([competence])
    end
  end
end
