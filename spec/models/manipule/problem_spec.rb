# frozen_string_literal: true

require "rails_helper"

RSpec.describe Manipule::Problem do
  describe "exactement une bonne réponse" do
    # C'est la seule chose qui, dans l'application, peut faire voir un rouge
    # injuste à un élève que personne n'est là pour rassurer.
    it "accepte un problème qui en a une" do
      expect(build(:manipule_problem)).to be_valid
    end

    it "refuse un problème qui n'en a aucune" do
      probleme = build(:manipule_problem)
      probleme.choices.each { |choix| choix.correct = false }

      expect(probleme).not_to be_valid
      expect(probleme.errors[:base]).to include("Une manipulation doit avoir exactement une bonne réponse")
    end

    it "refuse un problème qui en a deux" do
      probleme = build(:manipule_problem)
      probleme.choices.second.correct = true

      expect(probleme).not_to be_valid
    end

    it "ne compte pas une bonne réponse marquée pour suppression" do
      probleme = create(:manipule_problem)
      probleme.choices.find(&:correct?).mark_for_destruction

      expect(probleme).not_to be_valid
    end

    it "ne s'applique pas à un problème à saisie" do
      expect(build(:manipule_problem, :saisie)).to be_valid
    end
  end

  describe "le mode saisie" do
    it "exige une réponse attendue" do
      expect(build(:manipule_problem, :saisie, answer: nil)).not_to be_valid
    end

    it "accepte la réponse nue comme la réponse avec son unité" do
      probleme = build(:manipule_problem, :saisie)

      expect(probleme.accepte?("8")).to be true
      expect(probleme.accepte?("8 pommes")).to be true
      expect(probleme.accepte?("  8  POMMES ")).to be true
    end

    it "accepte une heure écrite autrement, en se rabattant sur les chiffres" do
      probleme = build(:manipule_problem, :saisie, answer: "9 h 45", unit: nil)

      expect(probleme.accepte?("9h45")).to be true
      expect(probleme.accepte?("9 h 45")).to be true
    end

    it "refuse une autre valeur, et refuse le vide" do
      probleme = build(:manipule_problem, :saisie)

      expect(probleme.accepte?("22")).to be false
      expect(probleme.accepte?("")).to be false
      expect(probleme.accepte?(nil)).to be false
    end
  end

  it "n'accepte qu'un outil connu" do
    expect(build(:manipule_problem, tool: "jetons")).to be_valid
    expect(build(:manipule_problem, tool: nil)).to be_valid
    expect(build(:manipule_problem, tool: "boulier")).not_to be_valid
  end

  it "tient son niveau de ceinture de sa compétence" do
    probleme = create(:manipule_problem)

    expect(probleme.level).to eq(probleme.skill.level)
  end

  it "refuse de se supprimer quand un élève y a déjà répondu" do
    serie = create(:manipule_practice)
    probleme = create(:manipule_problem, skill: serie.skill)
    serie.attempts.create!(problem: probleme, position: 1)

    expect(probleme.destroy).to be false
    expect(Manipule::Problem.exists?(probleme.id)).to be true
  end
  describe "les réglages des jetons" do
    def avec(donnees)
      build(:manipule_problem, tool: "jetons", tool_data: donnees)
    end

    it "retrouve le caractère de la ressource choisie" do
      expect(avec("ressource" => "carotte").jeton_caractere).to eq("🥕")
    end

    # Une banque importée peut nommer une ressource qu'on ne connaît pas : mieux
    # vaut un jeton par défaut qu'une case vide que l'élève ne peut pas saisir.
    it "retombe sur la pomme pour une ressource inconnue" do
      expect(avec("ressource" => "licorne").jeton_caractere).to eq("🍎")
      expect(avec({}).jeton_caractere).to eq("🍎")
    end

    # Trois cents jetons à l'écran ne se comptent pas, ils se subissent.
    it "plafonne la réserve" do
      expect(avec("reserve" => 300).jeton_reserve).to eq(described_class::RESERVE_MAX)
      expect(avec("reserve" => -4).jeton_reserve).to eq(0)
      expect(avec("reserve" => "15").jeton_reserve).to eq(15)
    end

    # Une zone sans nom ne serait qu'un rectangle muet : l'élève doit lire où
    # il pose, c'est ce qui relie le geste à l'énoncé.
    it "écarte les zones sans nom" do
      probleme = avec("zones" => ["Le panier", "  ", "", "Sur l'arbre"])

      expect(probleme.jeton_zones).to eq(["Le panier", "Sur l'arbre"])
    end

    # Six cases, c'est déjà beaucoup : on ne range pas des pommes dans six
    # endroits à la fois quand on a sept ans. Le plafond vaut aussi contre une
    # adresse forgée.
    it "plafonne le nombre de cases" do
      probleme = avec("zones" => (1..12).map { |rang| "Case #{rang}" })

      expect(probleme.jeton_zones.size).to eq(described_class::ZONES_MAX)
    end

    it "accepte plus de trois cases tant qu'on reste sous le plafond" do
      probleme = avec("zones" => ["Un", "Deux", "Trois", "Quatre"])

      expect(probleme.jeton_zones).to eq(%w[Un Deux Trois Quatre])
    end

    it "ne se croit pas équipé quand aucun outil n'est choisi" do
      expect(build(:manipule_problem).jetons?).to be(false)
    end
  end

end
