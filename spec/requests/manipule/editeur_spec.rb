# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Manipule, l'éditeur d'un problème" do
  # La factory :user fabrique un ADMIN, et un admin passe tous les gardes.
  let(:enseignante) { create(:user, admin: false, manipule: true) }
  let(:competence) do
    domaine = create(:domain, grade: create(:grade, school: enseignante.school))
    create(:skill, domain: domaine, school: enseignante.school, level: 1, name: "Recherche d'une partie")
  end

  before { sign_in enseignante }

  def champs(bonne: "1", **surcharges)
    {
      statement: "Il y a 15 pommes sur le pommier. Sam cueille 7 pommes.",
      question: "Combien reste-t-il de pommes sur le pommier ?",
      answer_mode: "choix",
      bonne_reponse: bonne,
      choices_attributes: {
        "0" => { label: "22 pommes", position: "1" },
        "1" => { label: "8 pommes", position: "2" },
        "2" => { label: "7 pommes", position: "3" }
      }
    }.merge(surcharges)
  end

  describe "le formulaire" do
    it "s'ouvre avec trois réponses vides" do
      get manipule_nouveau_probleme_path(competence)

      expect(response).to have_http_status(:ok)
      expect(response.body.scan("probleme[bonne_reponse]").size).to eq(3)
    end

    # Le piège que les specs ci-dessous ne peuvent pas voir : elles fabriquent
    # les paramètres à la main. Si le formulaire nommait ses champs autrement —
    # ce que fait `form_with` par défaut, d'après le modèle — rien ne se
    # rejoindrait, et l'aperçu répondrait 422 sans que l'écran le dise.
    it "nomme ses champs comme le contrôleur les attend" do
      get manipule_nouveau_probleme_path(competence)

      %w[statement question answer_mode tool].each do |champ|
        expect(response.body).to include(%(name="probleme[#{champ}]"))
      end
      expect(response.body).to include(%(name="probleme[choices_attributes][0][label]"))
      expect(response.body).to include(%(name="probleme[reglages][ressource]"))
      expect(response.body).not_to include("manipule_problem[")
    end

    it "se refuse sur la compétence d'une autre école" do
      autre = create(:skill, domain: create(:domain, grade: create(:grade)))

      get manipule_nouveau_probleme_path(autre)

      expect(response).to redirect_to(dashboard_path)
      expect(flash[:alert]).to be_present
    end
  end

  describe "la création" do
    it "crée un brouillon, jamais un problème en circulation" do
      expect { post manipule_problemes_path(competence), params: { probleme: champs } }.
        to change(Manipule::Problem, :count).by(1)

      probleme = Manipule::Problem.last
      expect(probleme.published).to be(false)
      expect(probleme.skill).to eq(competence)
      expect(probleme.user).to eq(enseignante)
    end

    # Le bouton radio porte la contrainte : exactement une bonne réponse, et
    # c'est celle que l'enseignante a désignée, pas la première de la liste.
    it "marque juste la réponse désignée, et elle seule" do
      post manipule_problemes_path(competence), params: { probleme: champs(bonne: "1") }

      choix = Manipule::Problem.last.choices.order(:position)
      expect(choix.map(&:label)).to eq(["22 pommes", "8 pommes", "7 pommes"])
      expect(choix.map(&:correct)).to eq([false, true, false])
    end

    it "suit le radio quand il désigne la troisième" do
      post manipule_problemes_path(competence), params: { probleme: champs(bonne: "2") }

      expect(Manipule::Problem.last.choices.order(:position).map(&:correct)).to eq([false, false, true])
    end

    it "range les réglages de l'outil dans la colonne structurée" do
      post manipule_problemes_path(competence), params: {
        probleme: champs.merge(tool: "jetons",
                               reglages: { ressource: "carotte", reserve: "12",
                                           zones: ["Le panier", "  ", "Sur l'arbre"] })
      }

      probleme = Manipule::Problem.last
      expect(probleme.jeton_caractere).to eq("🥕")
      expect(probleme.jeton_reserve).to eq(12)
      expect(probleme.jeton_zones).to eq(["Le panier", "Sur l'arbre"])
    end

    # Sans outil choisi, on ne laisse pas traîner des réglages orphelins qui
    # réapparaîtraient le jour où quelqu'un en choisit un.
    it "ne garde aucun réglage quand aucun outil n'est choisi" do
      post manipule_problemes_path(competence), params: {
        probleme: champs.merge(reglages: { ressource: "carotte", reserve: "12", zones: ["Le panier"] })
      }

      expect(Manipule::Problem.last.tool_data).to eq({})
    end

    it "garde les cases au-delà des deux proposées d'emblée" do
      post manipule_problemes_path(competence), params: {
        probleme: champs.merge(tool: "jetons",
                               reglages: { ressource: "pomme", reserve: "8",
                                           zones: ["Une", "Deux", "Trois", "Quatre"] })
      }

      expect(Manipule::Problem.last.jeton_zones).to eq(%w[Une Deux Trois Quatre])
    end

    it "réaffiche le formulaire sans rien créer quand l'énoncé manque" do
      expect { post manipule_problemes_path(competence), params: { probleme: champs(statement: "") } }.
        not_to change(Manipule::Problem, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("probleme[bonne_reponse]")
    end
  end

  describe "la modification" do
    let(:probleme) { create(:manipule_problem, skill: competence) }

    it "change l'énoncé sans toucher aux réponses" do
      patch manipule_probleme_path(probleme), params: {
        probleme: champs.merge(statement: "Il y a 20 pommes sur le pommier.",
                               choices_attributes: probleme.choices.order(:position).each_with_index.
                                 to_h { |choix, rang| [rang.to_s, { id: choix.id, label: choix.label, position: rang + 1 }] })
      }

      expect(probleme.reload.statement).to eq("Il y a 20 pommes sur le pommier.")
      expect(probleme.choices.count).to eq(3)
    end

    it "déplace la bonne réponse" do
      ancienne = probleme.choices.order(:position).first
      expect(ancienne.correct).to be(true)

      patch manipule_probleme_path(probleme), params: {
        probleme: champs(bonne: "2",
                         choices_attributes: probleme.choices.order(:position).each_with_index.
                           to_h { |choix, rang| [rang.to_s, { id: choix.id, label: choix.label, position: rang + 1 }] })
      }

      expect(ancienne.reload.correct).to be(false)
      expect(probleme.reload.choices.order(:position).last.correct).to be(true)
    end
  end

  describe "la duplication" do
    let!(:probleme) { create(:manipule_problem, skill: competence) }

    it "copie l'énoncé et les réponses" do
      expect { post manipule_dupliquer_probleme_path(probleme) }.
        to change(Manipule::Problem, :count).by(1)

      copie = Manipule::Problem.order(:id).last
      expect(copie.statement).to eq(probleme.statement)
      expect(copie.choices.order(:position).map(&:label)).to eq(probleme.choices.order(:position).map(&:label))
      expect(copie.choices.count(&:correct)).to eq(1)
    end

    # Une banque ne doit jamais se remplir toute seule : la copie n'est pas
    # relue, elle part en brouillon.
    it "part en brouillon même si l'original circule" do
      post manipule_dupliquer_probleme_path(probleme)

      expect(Manipule::Problem.order(:id).last.published).to be(false)
    end
  end

  describe "l'aperçu" do
    it "rend l'écran de l'élève sans rien enregistrer" do
      expect do
        post manipule_apercu_probleme_path(competence), params: { probleme: champs }
      end.not_to change(Manipule::Problem, :count)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Il y a 15 pommes").and include("8 pommes")
    end

    # C'est la vraie page de l'élève, pas une imitation : elle porte son
    # gabarit, donc sa feuille de style et son JavaScript.
    it "porte le gabarit de l'élève" do
      post manipule_apercu_probleme_path(competence), params: { probleme: champs }

      expect(response.body).to include("m-page").and include("assets/manipule")
    end

    it "montre l'outil quand il est choisi" do
      post manipule_apercu_probleme_path(competence), params: {
        probleme: champs.merge(tool: "jetons",
                               reglages: { ressource: "pomme", reserve: "4", zones: ["Le panier"] })
      }

      expect(response.body).to include("data-m-jetons").and include("Le panier")
      expect(response.body.scan(/aria-label="Jeton \d+"/).size).to eq(4)
    end

    # Le formulaire de MODIFICATION transmet les identifiants des réponses
    # existantes. L'aperçu, lui, fabrique un problème neuf : Rails cherchait
    # alors des enfants d'un parent sans identifiant, et levait.
    it "accepte les identifiants que le formulaire de modification transmet" do
      probleme = create(:manipule_problem, skill: competence)
      avec_ids = probleme.choices.order(:position).each_with_index.
        to_h { |choix, rang| [rang.to_s, { id: choix.id, label: choix.label, position: rang + 1 }] }

      post manipule_apercu_probleme_path(competence),
           params: { probleme: champs(choices_attributes: avec_ids) }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(probleme.choices.first.label)
    end

    it "ne tombe pas sur un formulaire encore vide" do
      post manipule_apercu_probleme_path(competence), params: {
        probleme: { statement: "", question: "", answer_mode: "choix" }
      }

      expect(response).to have_http_status(:ok)
    end
  end
  describe "la suppression" do
    let!(:probleme) { create(:manipule_problem, skill: competence) }

    it "supprime un problème que personne n'a travaillé" do
      expect { delete manipule_probleme_path(probleme) }.
        to change(Manipule::Problem, :count).by(-1)
    end

    # Un problème déjà passé par un élève ne se supprime pas : son historique
    # ferait mentir le suivi. On le dit, plutôt que de laisser une erreur
    # l'expliquer.
    it "refuse celui qu'un élève a déjà travaillé, et dit pourquoi" do
      eleve = create(:student, classroom: create(:classroom, user: enseignante))
      serie = Manipule::Practice.create!(student: eleve, skill: competence, started_at: Time.current)
      Manipule::Attempt.create!(practice: serie, problem: probleme, position: 1)

      expect { delete manipule_probleme_path(probleme) }.not_to change(Manipule::Problem, :count)
      expect(flash[:alert]).to include("déjà été travaillé")
    end
  end

end
