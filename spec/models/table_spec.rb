# frozen_string_literal: true

require "rails_helper"

RSpec.describe Table, type: :model do
  # `data` et `cell_styles` sont des grilles creuses indexées "<ligne>-<colonne>".
  # Toute opération structurelle doit décaler ces clés — c'est précisément ce que
  # l'implémentation précédente ne faisait pas : elle se contentait de retirer la
  # dernière ligne et laissait des orphelins dans `data`.

  describe "#insert_row!" do
    it "décale vers le bas les lignes situées à l'index d'insertion et en dessous" do
      table = described_class.create!(rows: 2, columns: 1, data: { "0-0" => "haut", "1-0" => "bas" })

      table.insert_row!(1)

      expect(table.rows).to eq(3)
      expect(table.data).to eq("0-0" => "haut", "2-0" => "bas")
    end

    it "n'ajoute rien au-delà de la limite" do
      table = described_class.create!(rows: described_class::MAX_ROWS, columns: 1)

      expect { table.insert_row!(0) }.not_to change(table, :rows)
    end
  end

  describe "#delete_row!" do
    it "supprime les données de la ligne et remonte les suivantes" do
      table = described_class.create!(rows: 3, columns: 1,
                                      data: { "0-0" => "a", "1-0" => "b", "2-0" => "c" })

      table.delete_row!(1)

      expect(table.rows).to eq(2)
      expect(table.data).to eq("0-0" => "a", "1-0" => "c")
    end

    it "décale aussi les styles de cellule" do
      table = described_class.create!(rows: 2, columns: 1, cell_styles: { "1-0" => ["b"] })

      table.delete_row!(0)

      expect(table.cell_styles).to eq("0-0" => ["b"])
    end

    it "refuse de supprimer la dernière ligne" do
      table = described_class.create!(rows: 1, columns: 2, data: { "0-0" => "a" })

      expect { table.delete_row!(0) }.not_to change(table, :rows)
      expect(table.data).to eq("0-0" => "a")
    end
  end

  describe "#insert_column!" do
    it "décale les colonnes et insère un alignement par défaut" do
      table = described_class.create!(rows: 1, columns: 2,
                                      data: { "0-0" => "a", "0-1" => "b" },
                                      col_aligns: %w[left right])

      table.insert_column!(1)

      expect(table.columns).to eq(3)
      expect(table.data).to eq("0-0" => "a", "0-2" => "b")
      expect(table.col_aligns).to eq(%w[left left right])
    end
  end

  describe "#delete_column!" do
    it "supprime la colonne, remonte les suivantes et retire son alignement" do
      table = described_class.create!(rows: 1, columns: 3,
                                      data: { "0-0" => "a", "0-1" => "b", "0-2" => "c" },
                                      col_aligns: %w[left center right])

      table.delete_column!(1)

      expect(table.columns).to eq(2)
      expect(table.data).to eq("0-0" => "a", "0-1" => "c")
      expect(table.col_aligns).to eq(%w[left right])
    end

    it "refuse de supprimer la dernière colonne" do
      table = described_class.create!(rows: 2, columns: 1)

      expect { table.delete_column!(0) }.not_to change(table, :columns)
    end
  end

  describe "#replace!" do
    it "écrit l'état complet envoyé par l'éditeur" do
      table = described_class.create!(rows: 1, columns: 1)

      table.replace!(
        "rows" => 2, "columns" => 2, "header_row" => "true",
        "data" => { "0-0" => "Mot", "1-1" => "chat" },
        "cell_styles" => { "1-1" => %w[b i] },
        "col_aligns" => %w[left center]
      )

      expect(table).to have_attributes(rows: 2, columns: 2, header_row: true)
      expect(table.data).to eq("0-0" => "Mot", "1-1" => "chat")
      expect(table.cell_styles).to eq("1-1" => %w[b i])
      expect(table.col_aligns).to eq(%w[left center])
    end

    it "écarte les cellules hors de la grille" do
      table = described_class.create!(rows: 3, columns: 3)

      table.replace!("rows" => 1, "columns" => 1, "data" => { "0-0" => "gardée", "2-2" => "hors grille" })

      expect(table.data).to eq("0-0" => "gardée")
    end

    it "ignore les clés de cellule mal formées et les drapeaux de style inconnus" do
      table = described_class.create!(rows: 1, columns: 1)

      table.replace!("data" => { "0-0" => "ok", "pas-une-clé" => "x" },
                     "cell_styles" => { "0-0" => %w[b script] })

      expect(table.data).to eq("0-0" => "ok")
      expect(table.cell_styles).to eq("0-0" => ["b"])
    end

    it "borne les dimensions" do
      table = described_class.create!(rows: 1, columns: 1)

      table.replace!("rows" => 9_999, "columns" => 0)

      expect(table.rows).to eq(described_class::MAX_ROWS)
      expect(table.columns).to eq(1)
    end

    it "laisse intactes les clés absentes de la charge utile" do
      table = described_class.create!(rows: 1, columns: 1, header_row: true, data: { "0-0" => "a" })

      table.replace!("rows" => 1, "columns" => 1)

      expect(table.header_row).to be(true)
      expect(table.data).to eq("0-0" => "a")
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
      expect(table.cell(0, 0)).to eq("a")
      expect(table.cell(0, 1)).to be_nil
    end

    it "tolère un alignement inconnu" do
      table = described_class.create!(rows: 1, columns: 1, col_aligns: ["justify"])

      expect(table.align_for(0)).to eq("left")
    end
  end
end
