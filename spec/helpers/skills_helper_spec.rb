# frozen_string_literal: true

require "rails_helper"

RSpec.describe SkillsHelper, type: :helper do
  def skill(position, sub_domain = nil, name = "Compétence #{position}")
    Skill.new(name:, sub_domain:, position:)
  end

  # La modale de validation groupait par sous-domaine dans une branche qui ne
  # s'exécutait jamais — la vue lisait `@sub_domains`, le contrôleur posait
  # `@subdomain`. Une fois les noms accordés, elle aurait perdu les compétences
  # sans sous-domaine : elle bouclait sur les sous-domaines trouvés, et ce qui
  # n'en a pas n'appartient à aucun.
  describe "#competences_par_sous_domaine" do
    it "met en tête, sous une clé sans nom, celles qui n'ont pas de sous-domaine" do
      groupes = helper.competences_par_sous_domaine([skill(1, "Les solides"), skill(2)])

      expect(groupes.first.first).to be_nil
      expect(groupes.first.last.map(&:position)).to eq([2])
    end

    # Le garde-fou qui compte : une compétence absente de la liste ne peut plus
    # être validée du tout.
    it "ne perd aucune compétence, quel que soit le mélange" do
      competences = [skill(1), skill(2, "Les solides"), skill(3), skill(4, "La symétrie")]

      rendues = helper.competences_par_sous_domaine(competences).flat_map(&:last)

      expect(rendues.map(&:position)).to match_array([1, 2, 3, 4])
    end

    # L'ordre est celui que l'enseignant a rangé, pas l'alphabet : les
    # sous-domaines sont des blocs contigus, et les trier par nom les ressortait
    # à l'envers de la séquence.
    it "range les groupes par la position de leur première compétence" do
      competences = [skill(1, "Les instruments"), skill(2, "Les instruments"),
                     skill(3, "La symétrie")]

      expect(helper.competences_par_sous_domaine(competences).map(&:first))
        .to eq(["Les instruments", "La symétrie"])
    end

    it "range les compétences par position dans chaque groupe" do
      competences = [skill(9, "Les solides"), skill(2, "Les solides")]

      expect(helper.competences_par_sous_domaine(competences).first.last.map(&:position))
        .to eq([2, 9])
    end

    it "ne se fie pas au nom pour ranger" do
      competences = [skill(1, nil, "Zoulou"), skill(2, nil, "Alpha")]

      expect(helper.competences_par_sous_domaine(competences).first.last.map(&:name))
        .to eq(%w[Zoulou Alpha])
    end

    # Un sous-domaine vide en base n'est pas un sous-domaine.
    it "traite une chaîne vide comme une absence de sous-domaine" do
      expect(helper.competences_par_sous_domaine([skill(1, "")]).map(&:first)).to eq([nil])
    end

    it "ne rend aucun groupe pour une liste vide" do
      expect(helper.competences_par_sous_domaine([])).to be_empty
    end
  end
end
