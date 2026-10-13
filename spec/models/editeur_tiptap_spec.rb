# frozen_string_literal: true

require "rails_helper"

RSpec.describe EditeurTiptap do
  def corps(html) = ActionText::RichText.new(body: ActionText::Content.new(html))

  def piece_jointe(table)
    %(<action-text-attachment sgid="#{table.attachable_sgid}" content-type="application/octet-stream"></action-text-attachment>)
  end

  describe ".contenu_initial" do
    it "donne à l'éditeur le corps au format de Trix" do
      expect(described_class.contenu_initial(corps("<div>Lis <strong>bien</strong></div>")))
        .to eq("<div>Lis <strong>bien</strong></div>")
    end

    it "convertit un tableau maison en tableau natif, en-tête et cases vides compris" do
      table = Table.create!(rows: 2, columns: 2, header_row: true, data: { "0-0" => "Mot", "1-1" => "chat" })

      html = described_class.contenu_initial(corps("<div>Classe#{piece_jointe(table)}</div>"))

      expect(html).to include('<table class="rt-table__grid"><tbody>')
      expect(html).to include('<th class="rt-cell"><div>Mot</div></th><th class="rt-cell"><div></div></th>')
      expect(html).to include('<td class="rt-cell"><div></div></td><td class="rt-cell"><div>chat</div></td>')
      expect(html).not_to include("data-trix-attachment")
    end

    # Perdu, l'en-tête ou les mots mis en valeur d'un tableau redevenaient du
    # texte ordinaire à la première ouverture dans l'éditeur.
    it "garde le style des cases : gras, italique, souligné, couleur, alignement" do
      table = Table.create!(rows: 1, columns: 2, data: { "0-0" => "chat", "0-1" => "nom" },
                            col_aligns: %w[left center], cell_styles: { "0-0" => %w[b i u] },
                            cell_colors: { "0-1" => "#F24150" })

      html = described_class.contenu_initial(corps(piece_jointe(table)))

      expect(html).to include('<td class="rt-cell"><div><strong><em><u>chat</u></em></strong></div></td>')
      expect(html).to include('<div style="text-align: center"><span style="color: #F24150">nom</span></div>')
    end

    it "écarte une couleur hors palette et garde les retours à la ligne d'une case" do
      table = Table.create!(rows: 1, columns: 1, data: { "0-0" => "un\ndeux" },
                            cell_colors: { "0-0" => "red; background: url(x)" })

      html = described_class.contenu_initial(corps(piece_jointe(table)))

      expect(html).to include("<div>un<br>deux</div>")
      expect(html).not_to include("url(x)")
    end

    it "échappe le texte d'une case" do
      table = Table.create!(rows: 1, columns: 1, data: { "0-0" => "3 < 5 & <b>" })

      expect(described_class.contenu_initial(corps(piece_jointe(table)))).to include("<div>3 &lt; 5 &amp; &lt;b&gt;</div>")
    end

    # ActionText juge un corps par son texte brut, et un tableau n'en a pas :
    # l'énoncé s'ouvrait vide, et l'enregistrement l'effaçait.
    it "n'ouvre pas vide un énoncé fait d'un seul tableau" do
      table = Table.create!(rows: 1, columns: 1, data: { "0-0" => "2 x 3" })

      expect(described_class.contenu_initial(corps(piece_jointe(table)))).to include("2 x 3")
    end

    # L'adresse enregistrée avec une image est figée au jour de l'envoi
    # (`http://127.0.0.1:3000/…` en local, un ancien domaine) : l'éditeur
    # affichait une image cassée.
    it "donne à une image retrouvée une adresse relative, valable sur tout serveur" do
      blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("png"), filename: "photo.png", content_type: "image/png")
      html = %(<action-text-attachment sgid="#{blob.attachable_sgid}" content-type="image/png" ) +
             %(url="http://127.0.0.1:3000/ancienne/adresse.png"></action-text-attachment>)

      contenu = described_class.contenu_initial(corps(html))

      expect(contenu).to include("/rails/active_storage/blobs/").and include("photo.png")
      expect(contenu).not_to include("127.0.0.1:3000")
    end

    it "garde son adresse à une image introuvable : c'est la seule qu'on ait" do
      html = %(<action-text-attachment sgid="illisible" content-type="image/png" url="https://exemple.test/i.png"></action-text-attachment>)

      expect(described_class.contenu_initial(corps(html))).to include("https://exemple.test/i.png")
    end

    it "laisse telle quelle une pièce jointe qui n'est pas un tableau" do
      figure = Figure.find("seyes")
      html = %(<action-text-attachment sgid="#{figure.attachable_sgid}" content-type="#{figure.content_type}"></action-text-attachment>)

      expect(described_class.contenu_initial(corps(html))).to include("data-trix-attachment")
    end

    it "laisse telle quelle une pièce jointe au sgid illisible" do
      html = %(<action-text-attachment sgid="illisible" content-type="application/octet-stream"></action-text-attachment>)

      expect { described_class.contenu_initial(corps(html)) }.not_to raise_error
    end

    it "rend une chaîne vide pour un énoncé vide" do
      expect(described_class.contenu_initial(nil)).to eq("")
      expect(described_class.contenu_initial(corps(""))).to eq("")
    end
  end
end
