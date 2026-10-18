# frozen_string_literal: true

require "rails_helper"

RSpec.describe Table, type: :model do
  # Le tableau maison ne s'édite plus (l'éditeur TipTap le convertit) : restent
  # la lecture, pour l'affichage, et la copie, pour le clonage.

  describe "couleur du texte des cellules" do
    # La couleur sort en `style` inline à l'affichage : liste blanche stricte,
    # aucune valeur arbitraire venue de la base n'atteint l'attribut.
    it "accepte une teinte de la palette" do
      table = described_class.create!(rows: 1, columns: 1, cell_colors: { "0-0" => "#F24150" })

      expect(table.color_for(0, 0)).to eq("#F24150")
    end

    it "écarte toute valeur hors palette" do
      table = described_class.create!(rows: 1, columns: 1, cell_colors: { "0-0" => "#123456" })

      expect(table.color_for(0, 0)).to be_nil
    end

    it "écarte une valeur qui tenterait de sortir de la déclaration CSS" do
      table = described_class.create!(rows: 1, columns: 1,
                                      cell_colors: { "0-0" => "red; background: url(javascript:alert(1))" })

      expect(table.color_for(0, 0)).to be_nil
    end

    it "n'expose que des hexadécimaux à six chiffres" do
      expect(described_class::TEXT_COLORS).to all(match(/\A#[0-9A-F]{6}\z/))
    end
  end

  describe "#duplicate" do
    it "donne un nouvel enregistrement, mise en forme comprise" do
      table = described_class.create!(rows: 1, columns: 2, header_row: true, data: { "0-0" => "chat" })

      copie = table.duplicate

      expect(copie).to be_persisted
      expect(copie.id).not_to eq(table.id)
      expect([copie.header_row?, copie.cell(0, 0)]).to eq([true, "chat"])
    end
  end

  describe "rétrocompatibilité" do
    # Un tableau créé avant l'ajout des colonnes de mise en forme n'a ni
    # en-tête, ni alignement, ni style : il doit se rendre exactement comme avant.
    it "se comporte comme avant quand les colonnes de mise en forme sont aux défauts" do
      table = described_class.create!(rows: 1, columns: 2, data: { "0-0" => "a" })

      expect(table.header_row?).to be(false)
      expect(table.align_for(0)).to eq("left")
      expect(table.align_for(1)).to eq("left")
      expect(table.styles_for(0, 0)).to eq([])
      expect(table.color_for(0, 0)).to be_nil
      expect(table.cell(0, 0)).to eq("a")
      expect(table.cell(0, 1)).to be_nil
    end

    it "tolère un alignement inconnu" do
      table = described_class.create!(rows: 1, columns: 1, col_aligns: ["justify"])

      expect(table.align_for(0)).to eq("left")
    end
  end
end
