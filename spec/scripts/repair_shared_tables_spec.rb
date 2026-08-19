# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("scripts/repair_shared_tables")

RSpec.describe SharedTableRepair do
  let(:output) { StringIO.new }
  let(:table) { Table.create!(rows: 2, columns: 2, header_row: true, data: { "0-0" => "chat" }) }

  # Trois exercices pointant sur le MÊME tableau : l'état laissé en base par
  # l'ancien clonage.
  def challenge_sharing(table, created_at:)
    create(:challenge, created_at: created_at).tap do |challenge|
      challenge.content =
        %(<div>Consigne</div><action-text-attachment sgid="#{table.attachable_sgid}" content-type="application/octet-stream"></action-text-attachment>)
      challenge.save!
    end
  end

  let!(:oldest) { challenge_sharing(table, created_at: 3.years.ago) }
  let!(:middle) { challenge_sharing(table, created_at: 2.years.ago) }
  let!(:newest) { challenge_sharing(table, created_at: 1.year.ago) }

  def table_of(challenge)
    challenge.reload.content.body.to_html.scan(/sgid="([^"]+)"/).flatten
             .filter_map { |sgid| Table.from_attachable_sgid(sgid) rescue nil }.first
  end

  describe "simulation" do
    it "n'écrit rien" do
      expect { described_class.new(dry_run: true, out: output).run }.not_to change(Table, :count)
      expect(table_of(newest).id).to eq(table.id)
    end

    it "annonce ce qu'elle ferait" do
      described_class.new(dry_run: true, out: output).run

      expect(output.string).to include("1 tableau(x) partagé(s)", "SIMULATION", "2 copie(s) de tableau à créer")
    end
  end

  describe "application" do
    before do
      FileUtils.rm_rf(described_class::DUMP_DIR)
      described_class.new(dry_run: false, confirm: 2, out: output).run
    end

    it "laisse son tableau au plus ancien" do
      expect(table_of(oldest).id).to eq(table.id)
    end

    it "donne une copie à chacun des autres" do
      copies = [middle, newest].map { |c| table_of(c).id }

      expect(copies).to all(satisfy { |id| id != table.id })
      expect(copies.uniq.size).to eq(2)
    end

    it "recopie le contenu et la mise en forme" do
      expect(table_of(newest)).to have_attributes(
        rows: 2, columns: 2, header_row: true, data: { "0-0" => "chat" }
      )
    end

    it "isole désormais les modifications" do
      table_of(newest).update!(data: { "0-0" => "chien" })

      expect(table.reload.cell(0, 0)).to eq("chat")
      expect(table_of(middle).cell(0, 0)).to eq("chat")
    end

    it "préserve le reste du corps" do
      expect(newest.reload.content.body.to_html).to include("Consigne")
    end

    it "écrit une sauvegarde des corps modifiés" do
      dump = Dir[described_class::DUMP_DIR.join("*.json")].max_by { |f| File.mtime(f) }
      payload = JSON.parse(File.read(dump))

      expect(payload["rich_texts"].map { |e| e["challenge_id"] }).to match_array([middle.id, newest.id])
      expect(payload["created_table_ids"].size).to eq(2)
      expect(payload["rich_texts"].first["body"]).to include(table.attachable_sgid)
    end

    it "est idempotent" do
      second_pass = StringIO.new

      expect { described_class.new(dry_run: false, confirm: 0, out: second_pass).run }.not_to change(Table, :count)
      expect(second_pass.string).to include("Aucun tableau partagé")
    end
  end

  describe "retour arrière" do
    # Le script écrit via update_columns, sans callback ni versionnement : la
    # sauvegarde est le seul chemin de retour.
    it "restitue l'état d'origine" do
      FileUtils.rm_rf(described_class::DUMP_DIR)
      described_class.new(dry_run: false, confirm: 2, out: output).run
      dump = Dir[described_class::DUMP_DIR.join("*.json")].max_by { |f| File.mtime(f) }
      copies = JSON.parse(File.read(dump))["created_table_ids"]

      described_class.new(restore: dump, out: output).run

      expect(table_of(middle).id).to eq(table.id)
      expect(table_of(newest).id).to eq(table.id)
      expect(Table.where(id: copies)).to be_empty
    end
  end

  # Cas rencontré en production : jusqu'à la refonte de l'éditeur, le partial de
  # tableau posait `id="table-<sgid>"`, et ce HTML est figé dans l'attribut
  # `content` de la pièce jointe. Le sgid apparaît donc DEUX fois dans le corps :
  # celui qu'on réécrit, et celui de l'instantané — que l'on ne doit pas toucher,
  # ActionText régénérant le partial à chaque rendu.
  describe "corps portant un instantané de l'ancien éditeur" do
    let(:snapshot) { %(<div class="table-editor" id="table-#{table.attachable_sgid}">…</div>) }

    before do
      [middle, newest].each do |challenge|
        challenge.content = %(<action-text-attachment sgid="#{table.attachable_sgid}" ) +
                            %(content-type="application/octet-stream" content="#{CGI.escapeHTML(snapshot)}"></action-text-attachment>)
        challenge.save!
      end
    end

    it "réassigne malgré l'ancien sgid figé dans l'instantané" do
      described_class.new(dry_run: false, confirm: 2, out: output).run

      expect(output.string).to include("2 copie(s) de tableau créées")
      expect(table_of(newest).id).not_to eq(table.id)
    end

    it "laisse l'instantané intact" do
      described_class.new(dry_run: false, confirm: 2, out: output).run

      expect(newest.reload.content.body.to_html).to include("table-#{table.attachable_sgid}")
    end
  end

  describe "garde-fous" do
    it "refuse d'écrire sans confirmation du périmètre" do
      expect { described_class.new(dry_run: false, out: output).run }.not_to change(Table, :count)
      expect(output.string).to include("Confirmation requise : 2 copie(s)", "CONFIRM=2")
    end

    it "refuse d'écrire si le périmètre annoncé ne correspond pas" do
      expect { described_class.new(dry_run: false, confirm: 99, out: output).run }.not_to change(Table, :count)
      expect(output.string).to include("Confirmation requise")
    end

    it "refuse si le sélecteur ne remplace aucun sgid" do
      allow_any_instance_of(ActionText::Fragment).to receive(:update).and_return(
        ActionText::Fragment.from_html(middle.reload.content.body.to_html)
      )

      described_class.new(dry_run: false, confirm: 2, out: output).run

      expect(output.string).to include("ANNULÉ", "aucun sgid remplacé")
    end

    it "annule TOUT si une vérification échoue en cours de route" do
      # On simule une copie infidèle sur le second exercice traité.
      call = 0
      allow_any_instance_of(Table).to receive(:duplicate).and_wrap_original do |method|
        call += 1
        copy = method.call
        copy.update_columns(columns: 99) if call == 2
        copy
      end

      expect { described_class.new(dry_run: false, confirm: 2, out: output).run }
        .not_to change { [middle, newest].map { |c| table_of(c).id } }

      expect(output.string).to include("ANNULÉ — aucune écriture conservée")
      expect(Table.where(columns: 99)).to be_empty
    end
  end
end
