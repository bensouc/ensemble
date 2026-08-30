# frozen_string_literal: true

require "rails_helper"

RSpec.describe SkillsHelper, type: :helper do
  def skill(name, sub_domain = nil)
    Skill.new(name:, sub_domain:)
  end

  # La modale de validation groupait par sous-domaine dans une branche qui ne
  # s'exécutait jamais — la vue lisait `@sub_domains`, le contrôleur posait
  # `@subdomain`. Une fois les noms accordés, elle aurait perdu les compétences
  # sans sous-domaine : elle bouclait sur les sous-domaines trouvés, et ce qui
  # n'en a pas n'appartient à aucun.
  describe "#competences_par_sous_domaine" do
    it "met en tête, sous une clé sans nom, celles qui n'ont pas de sous-domaine" do
      groupes = helper.competences_par_sous_domaine([skill("Bulle", "Les solides"), skill("Alpha")])

      expect(groupes.first.first).to be_nil
      expect(groupes.first.last.map(&:name)).to eq(["Alpha"])
    end

    # Le garde-fou qui compte : une compétence absente de la liste ne peut plus
    # être validée du tout.
    it "ne perd aucune compétence, quel que soit le mélange" do
      competences = [skill("Alpha"), skill("Bulle", "Les solides"), skill("Charlie"),
                     skill("Delta", "La symétrie")]

      rendues = helper.competences_par_sous_domaine(competences).flat_map(&:last)

      expect(rendues.map(&:name)).to match_array(%w[Alpha Bulle Charlie Delta])
    end

    it "range les sous-domaines par ordre alphabétique" do
      competences = [skill("Alpha", "Les solides"), skill("Bulle", "La symétrie")]

      expect(helper.competences_par_sous_domaine(competences).map(&:first))
        .to eq(["La symétrie", "Les solides"])
    end

    it "range les compétences par nom dans chaque groupe" do
      competences = [skill("Zoulou", "Les solides"), skill("Alpha", "Les solides")]

      expect(helper.competences_par_sous_domaine(competences).first.last.map(&:name))
        .to eq(%w[Alpha Zoulou])
    end

    # Un sous-domaine vide en base n'est pas un sous-domaine.
    it "traite une chaîne vide comme une absence de sous-domaine" do
      expect(helper.competences_par_sous_domaine([skill("Alpha", "")]).map(&:first)).to eq([nil])
    end

    it "ne rend aucun groupe pour une liste vide" do
      expect(helper.competences_par_sous_domaine([])).to be_empty
    end
  end
end
