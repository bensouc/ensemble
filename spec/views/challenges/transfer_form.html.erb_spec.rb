# frozen_string_literal: true

require "rails_helper"

# Le contenu de la modale de déplacement. Il se recharge à chaque choix de
# ceinture : c'est une frame, pas une page.
RSpec.describe "challenges/transfer_form" do
  let(:school) { create(:school) }
  let(:domain) { create(:domain) }
  let(:depart) { create(:skill, domain:, school:, level: 3, name: "Compétence de départ") }
  let(:challenge) { create(:challenge, skill: depart, name: "Mon exercice") }

  def rendre(skills)
    assign(:challenge, challenge)
    assign(:domain, domain)
    assign(:level, 3)
    assign(:skills, skills)
    render template: "challenges/transfer_form"
  end

  it "se rend dans la frame de l'exercice, pour se recharger sans quitter la modale" do
    rendre([])

    expect(rendered).to include(%(id="transfer_challenge_#{challenge.id}"))
  end

  # On ne change ni de niveau ni de domaine : le dire évite de chercher un
  # réglage qui n'existe pas.
  it "rappelle qu'on reste dans le domaine" do
    rendre([])

    expect(rendered).to include(domain.name)
  end

  it "propose les sept ceintures, celle de l'exercice sélectionnée" do
    rendre([])

    Belt::BELT_COLORS.each { |couleur| expect(rendered).to include(couleur.capitalize) }
    expect(rendered).to match(/<option[^>]*selected="selected"[^>]*value="3"/)
  end

  # On reconnaît le niveau à la teinte avant d'avoir lu le mot.
  it "colore chaque ceinture de sa couleur" do
    rendre([])

    expect(rendered).to include('class="--bgc-jaune" value="2"')
    expect(rendered).to include('class="--bgc-noir --blanc" value="7"')
  end

  it "colore le champ lui-même de la ceinture en cours" do
    rendre([])

    expect(rendered).to match(/<select[^>]*class="[^"]*--bgc-orange/)
  end

  # Les ceintures foncées passent le texte en blanc, sinon il disparaît dessus.
  it "éclaircit le texte sur les ceintures foncées" do
    rendre([])

    expect(rendered).to include("--bgc-vert --blanc")
  end

  it "offre un bouton par compétence d'arrivée" do
    arrivee = create(:skill, domain:, school:, level: 3, name: "Compétence d'arrivée")

    rendre([arrivee])

    expect(rendered).to include("Compétence d'arrivée")
    expect(rendered).to include(%(value="#{arrivee.id}"))
    expect(rendered).to include(transfer_challenge_path(challenge))
  end

  # Une ceinture peut n'avoir aucune autre compétence dans ce domaine : le dire,
  # plutôt que de laisser une modale vide.
  it "explique quand la ceinture choisie n'offre rien" do
    rendre([])

    expect(rendered).to include("Aucune autre compétence à cette ceinture")
  end

  # La liste re-rendue emporte le nœud de la modale : sans fermeture explicite,
  # Bootstrap laisserait son voile noir sur la page.
  it "referme la modale avant d'envoyer" do
    rendre([create(:skill, domain:, school:, level: 3)])

    expect(rendered).to include('data-bs-dismiss="modal"')
  end
end
