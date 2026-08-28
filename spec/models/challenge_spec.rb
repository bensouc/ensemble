# frozen_string_literal: true

require "rails_helper"
RSpec.describe Challenge, type: :model do
  before(:all) do
    Challenge.destroy_all
    SchoolRole.destroy_all
    User.destroy_all
    @challenge1 = create(:challenge)
  end

  it " is valid with valid attributes" do
    expect(@challenge1).to be_valid
  end

  it "has a unique name for the same Skill" do
    challenge2 = build(:challenge, name: @challenge1.name, skill: @challenge1.skill)
    expect(challenge2).to_not be_valid
  end

  # La mise en forme de bloc — alignement, interligne — est portée par `style`
  # justement parce que `style` traverse le sanitizer d'ActionText sans qu'on ait à
  # toucher son allowlist. Une balise maison, elle, en serait retirée à l'affichage :
  # le texte resterait, la mise en forme serait perdue.
  describe "mise en forme de bloc à l'affichage" do
    it "conserve l'alignement d'un paragraphe et d'un titre" do
      challenge = create(:challenge)
      challenge.content = <<~HTML
        <p style="text-align: center">Centré</p>
        <h1 style="text-align: right">Titre à droite</h1>
        <div>Paragraphe normal</div>
      HTML
      challenge.save!

      rendered = challenge.reload.content.to_s

      expect(rendered).to include("text-align:center")
      expect(rendered).to include("text-align:right")
      expect(rendered).to include("Paragraphe normal")
    end

    it "conserve l'interligne, seul ou combiné à l'alignement" do
      challenge = create(:challenge)
      challenge.content = <<~HTML
        <p style="line-height: 3">Trois lignes d'écart pour écrire</p>
        <p style="text-align: center; line-height: 2">Centré et aéré</p>
      HTML
      challenge.save!

      rendered = challenge.reload.content.to_s

      expect(rendered).to include("line-height:3")
      # les deux déclarations vivent dans le même style : aucune ne doit sauter
      expect(rendered).to include("text-align:center")
      expect(rendered).to include("line-height:2")
    end

    it "retire une balise maison — d'où le choix de `style`" do
      rendered = ActionText::Content.new("<trix-align-center>Centré</trix-align-center>").to_s

      # le texte survit, mais la balise qui portait l'alignement a disparu
      expect(rendered).to include("Centré")
      expect(rendered).not_to include("trix-align-center")
    end
  end

  describe "ordre au sein d'une compétence" do
    let(:skill) { create(:skill) }

    it "place un nouvel exercice en fin de liste" do
      first = create(:challenge, skill:)
      second = create(:challenge, skill:)

      expect([first.position, second.position]).to eq([1, 2])
    end

    it "numérote séparément les exercices classiques et ceux de ceinture" do
      classic = create(:challenge, skill:)
      belt = create(:challenge, skill:, for_belt: true)

      expect([classic.position, belt.position]).to eq([1, 1])
    end

    it "échange deux positions avec move_higher / move_lower" do
      first = create(:challenge, skill:)
      second = create(:challenge, skill:)

      second.move_higher

      expect([first.reload.position, second.reload.position]).to eq([2, 1])

      second.move_lower

      expect([first.reload.position, second.reload.position]).to eq([1, 2])
    end

    it "renumérote la liste quand un exercice est supprimé" do
      create(:challenge, skill:)
      middle = create(:challenge, skill:)
      last = create(:challenge, skill:)

      middle.destroy

      expect(last.reload.position).to eq(2)
    end

    it "crée un exercice vide en fin de liste" do
      create(:challenge, skill:)
      user = create(:user)

      empty = Challenge.create_empty(skill, user)

      expect(empty.position).to eq(2)
      expect(empty.user).to eq(user)
      expect(empty.content.to_plain_text).to include("REDIGER")
      expect(empty).to be_persisted
    end

    it "crée un exercice vide même quand le nom construit sur le compteur est pris" do
      taken = create(:challenge, skill:, name: "#{skill.name} 1-NEW")

      empty = Challenge.create_empty(skill, create(:user))

      expect(empty).to be_persisted
      expect(empty.name).not_to eq(taken.name)
    end

    it "ordonne la liste avec le scope ordered" do
      first = create(:challenge, skill:)
      second = create(:challenge, skill:)
      second.move_to_top

      expect(Challenge.where(skill:).ordered.to_a).to eq([second, first])
    end
  end

  # Un exercice tient à son grade, via la compétence, pas à la personne qui l'a
  # écrit : il doit survivre au départ de son auteur.
  describe "sans auteur" do
    it "reste valide et enregistrable" do
      challenge = create(:challenge)
      challenge.user = nil

      expect(challenge).to be_valid
      expect(challenge.save).to be true
    end
  end

  # Déplacer un exercice sous une autre compétence.
  #
  # `update!(skill:)` seul ne suffit pas : `acts_as_list` (0.7.7) ignore le
  # changement de liste. Mesuré avant correction — la liste d'origine passait de
  # 1,2,3,4 à 1,2,4 (un trou), et l'exercice emportait son ancienne position dans
  # la liste d'arrivée, où elle entrait en collision. Ces specs sont le garde-fou
  # de l'ordre des exercices, qui est une fonctionnalité à part entière.
  describe "#transfer_to_skill!" do
    let(:school) { create(:school) }
    let(:domain) { create(:domain) }
    let(:depart) { create(:skill, domain:, school:, level: 3) }
    let(:arrivee) { create(:skill, domain:, school:, level: 3) }
    let(:auteur) { create(:user) }

    def exercice(nom, competence, for_belt: false)
      create(:challenge, name: nom, skill: competence, user: auteur, for_belt:)
    end

    def positions(competence, for_belt: false)
      Challenge.where(skill: competence, for_belt:).order(:position).pluck(:name, :position)
    end

    it "referme le trou laissé dans la compétence d'origine" do
      premier = exercice("A", depart)
      exercice("B", depart)
      exercice("C", depart)

      premier.transfer_to_skill!(arrivee, auteur: auteur)

      expect(positions(depart)).to eq([["B", 1], ["C", 2]])
    end

    it "ajoute l'exercice en QUEUE de la liste d'arrivée" do
      voyageur = exercice("A", depart)
      exercice("B", depart)
      exercice("déjà là", arrivee)
      exercice("déjà là aussi", arrivee)

      voyageur.transfer_to_skill!(arrivee, auteur: auteur)

      expect(positions(arrivee)).to eq([["déjà là", 1], ["déjà là aussi", 2], ["A", 3]])
    end

    # Le cas qui cassait : l'exercice arrivait avec sa position d'origine, déjà
    # occupée dans la liste d'arrivée.
    it "ne crée aucune position en double, même en cas de collision" do
      exercice("A", depart)
      exercice("B", depart)
      voyageur = exercice("C", depart) # position 3
      3.times { |i| exercice("cible #{i}", arrivee) } # occupe 1, 2 et 3

      voyageur.transfer_to_skill!(arrivee, auteur: auteur)

      rangs = Challenge.where(skill: arrivee).pluck(:position)
      expect(rangs.uniq.size).to eq(rangs.size)
      expect(rangs.sort).to eq([1, 2, 3, 4])
    end

    it "laisse les deux listes en suite continue" do
      voyageur = exercice("A", depart)
      exercice("B", depart)
      exercice("C", depart)
      exercice("X", arrivee)

      voyageur.transfer_to_skill!(arrivee, auteur: auteur)

      expect(positions(depart).map(&:last)).to eq([1, 2])
      expect(positions(arrivee).map(&:last)).to eq([1, 2])
    end

    # Un exercice de ceinture reste un exercice de ceinture, un exercice de
    # compétence reste un exercice de compétence : les deux listes ne se
    # mélangent JAMAIS.
    it "conserve la nature de l'exercice" do
      ceinture = exercice("ceinture", depart, for_belt: true)

      ceinture.transfer_to_skill!(arrivee, auteur: auteur)

      expect(ceinture.reload.for_belt).to be true
    end

    it "n'entre que dans la liste de sa propre nature" do
      exercice("classique déjà là", arrivee, for_belt: false)
      ceinture = exercice("ceinture", depart, for_belt: true)

      ceinture.transfer_to_skill!(arrivee, auteur: auteur)

      expect(positions(arrivee, for_belt: true)).to eq([["ceinture", 1]])
      expect(positions(arrivee, for_belt: false)).to eq([["classique déjà là", 1]])
    end

    # Déplacer, c'est reprendre l'exercice à son compte : c'est le prof qui
    # déplace qui décide désormais de sa place dans la progression.
    it "donne l'exercice à celui qui le déplace" do
      repreneur = create(:user)
      voyageur = exercice("A", depart)

      voyageur.transfer_to_skill!(arrivee, auteur: repreneur)

      expect(voyageur.reload.user).to eq(repreneur)
    end

    it "change bien de compétence" do
      voyageur = exercice("A", depart)

      voyageur.transfer_to_skill!(arrivee, auteur: auteur)

      expect(voyageur.reload.skill).to eq(arrivee)
    end
  end
end
