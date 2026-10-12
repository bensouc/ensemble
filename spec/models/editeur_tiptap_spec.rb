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
