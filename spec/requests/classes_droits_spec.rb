# frozen_string_literal: true

require "rails_helper"

# Renommer une classe : son enseignant, les collègues du partage, les admins —
# ceux qui la voient dans leur liste. Le contrôleur sautait l'autorisation, et
# n'importe quel enseignant connecté renommait la classe d'une autre école en
# donnant son id.
RSpec.describe "Droits sur les classes", type: :request do
  let(:ecole) { create(:school) }
  let(:enseignant) { create(:user, school: ecole, admin: false) }
  let(:classe) { create(:classroom, user: enseignant, name: "CE1 A") }

  def renommer(nom)
    patch classroom_path(classe), params: { classroom: { name: nom } }
    classe.reload.name
  end

  it "refuse à un enseignant d'une autre école" do
    sign_in create(:user, admin: false)

    expect(renommer("Piratée")).to eq("CE1 A")
  end

  it "refuse à un collègue de l'école à qui la classe n'est pas partagée" do
    sign_in create(:user, school: ecole, admin: false)

    expect(renommer("Piratée")).to eq("CE1 A")
  end

  it "laisse l'enseignant de la classe la renommer" do
    sign_in enseignant

    expect(renommer("CE1 Les loutres")).to eq("CE1 Les loutres")
  end

  it "laisse un collègue du partage la renommer" do
    collegue = create(:user, school: ecole, admin: false)
    create(:shared_classroom, user: collegue, classroom: classe)
    sign_in collegue

    expect(renommer("CE1 Les loutres")).to eq("CE1 Les loutres")
  end

  # Le niveau vient du formulaire. Une classe ouverte sur le niveau d'une autre
  # école en donnait les compétences et les exercices, par l'index des exercices
  # qui part des niveaux de ses classes.
  describe "création" do
    # Un compte démo échappe au plafond de l'abonnement : seul le niveau décide.
    before do
      enseignant.update!(demo: true)
      sign_in enseignant
    end

    def creer_sur(niveau)
      post classrooms_path, params: { classroom: { grade_id: niveau.id, name: "CE1 B" } }
    end

    it "refuse le niveau d'une autre école" do
      expect { creer_sur(create(:grade)) }.not_to change(Classroom, :count)
    end

    it "accepte un niveau de son école" do
      expect { creer_sur(create(:grade, school: ecole)) }.to change(Classroom, :count).by(1)
    end
  end

  # Partager sa classe, c'est ouvrir ses élèves : à un collègue de l'école, pas à
  # n'importe quel compte désigné par son id.
  describe "partage" do
    before do
      create(:user, admin: true) # signe le message qui annonce le partage
      sign_in enseignant
    end

    def partager_avec(enseignants)
      post classroom_shared_classrooms_path(classe),
           params: { classe.id.to_s => { teachers: [""] + enseignants.map { |e| e.id.to_s } } }
    end

    it "refuse un enseignant d'une autre école" do
      expect { partager_avec([create(:user, admin: false)]) }.not_to change(SharedClassroom, :count)
    end

    it "partage avec un collègue de l'école" do
      expect { partager_avec([create(:user, school: ecole, admin: false)]) }.to change(SharedClassroom, :count).by(1)
    end
  end
end
