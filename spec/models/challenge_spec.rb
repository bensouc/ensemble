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

end
