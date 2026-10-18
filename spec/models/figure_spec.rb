# frozen_string_literal: true

require "rails_helper"

RSpec.describe Figure do
  def piece_jointe(id, presentation: nil)
    figure = described_class.find(id)
    attributs = %(sgid="#{figure.attachable_sgid}" content-type="#{figure.content_type}")
    attributs += %( presentation="#{presentation}") if presentation
    "<action-text-attachment #{attributs}></action-text-attachment>"
  end

  def rendu(html)
    ActionText::Content.new(html).to_rendered_html_with_layout
  end

  describe ".id_for" do
    it "décrit une ligne Seyès, avec ou sans marge" do
      expect(described_class.id_for(kind: "seyes")).to eq("seyes")
      expect(described_class.id_for(kind: "seyes", marge: true)).to eq("seyes-marge")
    end

    it "lit l'heure tapée par l'enseignant, sur un cadran de 12 heures" do
      expect(described_class.id_for(kind: "horloge", heure: "3:15")).to eq("horloge-0315-chiffres")
      expect(described_class.id_for(kind: "horloge", heure: "15h15")).to eq("horloge-0315-chiffres")
      expect(described_class.id_for(kind: "horloge", heure: "12 h", chiffres: false)).to eq("horloge-1200-nue")
      expect(described_class.id_for(kind: "horloge", heure: "0:30")).to eq("horloge-1230-chiffres")
    end

    it "donne une horloge sans aiguilles quand l'heure est vide" do
      expect(described_class.id_for(kind: "horloge", heure: " ")).to eq("horloge-vide-chiffres")
    end

    it "refuse une heure ou un pictogramme qui n'existent pas" do
      expect(described_class.id_for(kind: "horloge", heure: "25:00")).to be_nil
      expect(described_class.id_for(kind: "horloge", heure: "trois heures")).to be_nil
      expect(described_class.id_for(kind: "picto", nom: "licorne")).to be_nil
      expect(described_class.id_for(kind: "autre")).to be_nil
    end
  end

  it "se retrouve par son sgid, sans rien en base" do
    figure = described_class.find("horloge-0945-nue")

    expect(ActionText::Attachable.from_attachable_sgid(figure.attachable_sgid)).to eq(figure)
  end

  it "devient une pièce jointe manquante quand son identifiant ne veut rien dire" do
    expect { described_class.find("horloge-9999-chiffres") }.to raise_error(ActiveRecord::RecordNotFound)
  end

  describe "rendu de l'énoncé" do
    it "dessine l'horloge en SVG, aiguilles comprises" do
      html = rendu(piece_jointe("horloge-0315-chiffres"))

      expect(html).to include('aria-label="Horloge : 3 h 15"')
      expect(html.scan("<line").size).to eq(62) # 60 graduations et 2 aiguilles
      expect(html).to include(">12</text>")
    end

    it "laisse l'horloge sans aiguilles ni chiffres quand on le demande" do
      html = rendu(piece_jointe("horloge-vide-nue"))

      expect(html.scan("<line").size).to eq(60)
      expect(html).not_to include("<text")
    end

    it "applique la taille et la position choisies dans l'éditeur" do
      html = rendu(piece_jointe("horloge-0315-chiffres", presentation: "taille-50 centre"))

      expect(html).to include("width:50%").and include("rt-fig--centre")
    end

    it "donne un quart de la largeur à une horloge sans taille" do
      expect(rendu(piece_jointe("horloge-0315-chiffres"))).to include("width:25%")
    end

    it "dessine une ligne simple pour écrire dessus" do
      expect(described_class.id_for(kind: "ligne")).to eq("ligne")

      html = rendu(piece_jointe("ligne", presentation: "taille-50 gauche"))

      expect(html).to include("rt-figure--ligne").and include('aria-label="Ligne d\'écriture"')
      expect(html).to include("width:50%").and include("rt-fig--gauche")
    end

    it "dessine trois rangées de petits carreaux, fermées en haut et en bas" do
      expect(described_class.id_for(kind: "carreaux")).to eq("carreaux")

      html = rendu(piece_jointe("carreaux"))
      geometrie = described_class.find("carreaux").carreaux_geometrie

      expect(html).to include("rt-figure--carreaux").and include('aria-label="Ligne à petits carreaux"')
      # un trait sur chaque bord : deux figures collées n'en font qu'un, entier
      expect(geometrie[:lignes].size).to eq(4)
      expect([geometrie[:lignes].first, geometrie[:lignes].last]).to eq([0, geometrie[:hauteur]])
    end

    describe "matériel de manipulation" do
      it "connaît les billets, les pièces et les blocs de numération, et eux seuls" do
        expect(described_class.id_for(kind: "billet", nom: "20")).to eq("billet-20")
        expect(described_class.id_for(kind: "piece", nom: "2")).to eq("piece-2")
        expect(described_class.id_for(kind: "bloc", nom: "centaine")).to eq("bloc-centaine")
        expect(described_class.id_for(kind: "billet", nom: "7")).to be_nil
        expect(described_class.id_for(kind: "piece", nom: "5")).to be_nil
      end

      it "se dessine dans la ligne, avec sa valeur lisible" do
        html = rendu(piece_jointe("billet-100"))

        expect(html).to include("rt-figure--billet-100").and include('aria-label="Billet de 100 €"')
        expect(html).to include(">100</text>")
        expect(described_class.find("billet-100")).to be_inline
      end

      it "dessine un millier en cube quadrillé, plus grand qu'une centaine" do
        millier = described_class.find("bloc-millier")
        centaine = described_class.find("bloc-centaine")

        expect(millier.libelle).to eq("Un millier")
        expect(millier.taille_du_materiel[1]).to be > centaine.taille_du_materiel[1]
        expect(rendu(piece_jointe("bloc-millier"))).to include("<polygon").and include('stroke="#FFFFFF"')
      end
    end

    it "donne à la ligne simple la hauteur d'un carreau Seyès, à l'écran comme au PDF" do
      ligne = described_class.find("ligne")
      seyes = described_class.find("seyes")

      [false, true].each do |pdf|
        expect(ligne.ligne_geometrie(pdf:)[:hauteur]).to eq(seyes.seyes_geometrie(pdf:)[:carreau])
      end
    end

    it "laisse la ligne Seyès en pleine largeur tant qu'aucune taille n'est choisie" do
      html = rendu(piece_jointe("seyes-marge"))

      expect(html).to include("rt-figure--seyes").and include("rt-figure--marge")
      expect(html).not_to include("width:")
    end

    it "place un pictogramme dans la phrase" do
      html = rendu("<div>Coche : #{piece_jointe('picto-case')} oui</div>")

      expect(html).to match(/Coche :\s*<span class="rt-figure rt-figure--picto">/)
      expect(html).to include('aria-label="Case à cocher"')
    end

    it "se lit en texte brut" do
      texte = ActionText::Content.new("#{piece_jointe('horloge-0315-chiffres')}#{piece_jointe('picto-coche')}").to_plain_text

      expect(texte).to eq("[Horloge : 3 h 15][Coche]")
    end
  end

  describe "dans l'éditeur" do
    it "passe en image, parce que Trix retire les tracés d'un SVG en ligne" do
      html = ApplicationController.render(partial: "figures/editor",
                                          locals: { figure: described_class.find("picto-crayon") })

      expect(html).to include('src="data:image/svg+xml;base64,')
    end
  end

  describe "au clonage d'un exercice" do
    it "garde la même figure et sa taille" do
      challenge = create(:challenge, content: piece_jointe("seyes", presentation: "taille-75 droite"))

      clone_html = challenge.reload.new_clone.content.body.to_html

      expect(clone_html).to include(described_class.find("seyes").attachable_sgid)
      expect(clone_html).to include('presentation="taille-75 droite"')
    end
  end
end

RSpec.describe FigurePresentation do
  it "ne change rien à une image déjà en place" do
    expect(described_class.parse("gallery")).to be_nil
    expect(described_class.parse(nil)).to be_nil
  end

  it "lit une taille libre et une position" do
    expect(described_class.parse("taille-25 gauche")).to eq([25, "gauche"])
    expect(described_class.parse("taille-33 centre")).to eq([33, "centre"])
    expect(described_class.parse("taille-100")).to eq([100, nil])
  end

  it "ignore une taille hors bornes ou une position inventée" do
    expect(described_class.parse("taille-5 centre")).to be_nil
    expect(described_class.parse("taille-150 centre")).to be_nil
    expect(described_class.parse("taille-50 partout")).to eq([50, nil])
  end
end

# Une image au sgid illisible (toutes celles de la base de dev, signées avec la
# clé de la prod) passe par le gabarit `remote_image` : il ignorait la taille.
RSpec.describe "Taille d'une image affichée par son adresse" do
  it "est appliquée comme pour une image retrouvée" do
    corps = %(<action-text-attachment sgid="illisible" content-type="image/png" url="https://exemple.test/i.png" ) +
            %(width="400" height="300" presentation="taille-35 gauche"></action-text-attachment>)

    html = ActionText::Content.new(corps).to_rendered_html_with_layout

    expect(html).to include("rt-fig rt-fig--gauche").and include("width:35%")
  end
end

# Bloc « colonnes » de l'éditeur : des <div> à classes, que le sanitizer garde.
RSpec.describe "Colonnes d'un énoncé" do
  it "gardent leurs classes au rendu, donc leur mise en page" do
    corps = %(<div class="rt-colonnes rt-colonnes--2"><div class="rt-colonne"><div>chat</div></div>) +
            %(<div class="rt-colonne"><div>chien</div></div></div>)

    expect(ActionText::Content.new(corps).to_rendered_html_with_layout)
      .to include('<div class="rt-colonnes rt-colonnes--2"><div class="rt-colonne"><div>chat</div></div>')
  end
end
