# frozen_string_literal: true

require "rails_helper"

# `.sort` sur ces modèles ne triait PAS par position : ActiveRecord définit
# `<=>` sur la clé primaire, et aucun ne le redéfinissait. Les listes sortaient
# dans l'ordre de leur création — silencieusement, y compris sur la page de
# résultats d'une classe et l'index des compétences.
RSpec.describe Positionable do
  let(:modeles_ranges) { [Challenge, Skill, Domain, WorkPlanSkill] }

  it "est inclus par tous les modèles que l'enseignant range" do
    expect(modeles_ranges).to all(include(described_class))
  end

  it "donne à chacun un scope `ordered`" do
    modeles_ranges.each do |modele|
      expect(modele.ordered.to_sql).to include("position", "ASC")
    end
  end

  describe "l'ordre en Ruby" do
    let(:domain) { create(:domain) }
    let(:school) { create(:school) }

    def competence(position, nom)
      create(:skill, domain:, school:, level: 3, name: nom).tap do |skill|
        skill.update_column(:position, position)
      end
    end

    # Le cas qui piégeait : la plus ancienne — donc le plus petit id — devait
    # sortir en dernier.
    it "trie par position, pas par ordre de création" do
      ancienne = competence(9, "rangée en dernier")
      recente = competence(1, "rangée en premier")

      expect([ancienne, recente].sort.map(&:name)).to eq(["rangée en premier", "rangée en dernier"])
      expect(ancienne.id).to be < recente.id
    end

    # Quatre scopes de la base ont deux enregistrements à la même position :
    # l'ordre doit rester le même d'un affichage à l'autre.
    it "départage par id les positions égales" do
      premiere = competence(4, "a")
      seconde = competence(4, "b")

      expect([seconde, premiere].sort).to eq([premiere, seconde])
    end

    it "trie de la même façon en SQL et en Ruby" do
      competence(9, "dernière")
      competence(1, "première")

      en_sql = Skill.where(domain:, level: 3).ordered.map(&:name)
      en_ruby = Skill.where(domain:, level: 3).to_a.sort.map(&:name)

      expect(en_ruby).to eq(en_sql)
    end

    it "laisse la comparaison d'origine aux objets d'une autre classe" do
      expect(competence(1, "x") <=> create(:domain)).to be_nil
    end
  end
end
