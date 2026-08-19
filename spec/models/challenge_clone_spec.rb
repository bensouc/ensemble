# frozen_string_literal: true

require "rails_helper"

# Le clonage d'un exercice recopie son corps ActionText. Tout se joue sur le
# fait de travailler sur le HTML BRUT : `ActionText::Content#to_s` rend et
# sanitise, ce qui supprime les balises `action-text-attachment`. La version
# précédente s'appuyait dessus, si bien que son clonage de tableaux n'a jamais
# tourné — 20 tableaux étaient référencés par plusieurs exercices en base, et
# éditer une cellule depuis l'un modifiait silencieusement les autres.
RSpec.describe "Clonage d'un exercice", type: :model do
  let(:challenge) { create(:challenge) }

  def attach(*nodes)
    challenge.content = nodes.join("\n")
    challenge.save!
    challenge.reload
  end

  def tables_in(record)
    record.content.body.to_html.scan(/sgid="([^"]+)"/).flatten
          .filter_map { |sgid| Table.from_attachable_sgid(sgid) rescue nil }
  end

  describe "tableaux" do
    let(:table) { Table.create!(rows: 2, columns: 2, header_row: true, data: { "0-0" => "chat" }) }

    before do
      attach(%(<action-text-attachment sgid="#{table.attachable_sgid}" content-type="application/octet-stream"></action-text-attachment>))
    end

    it "donne au clone son propre enregistrement" do
      clone = challenge.new_clone

      expect(tables_in(clone).map(&:id)).not_to include(table.id)
    end

    it "recopie le contenu et la mise en forme du tableau" do
      clone = challenge.new_clone

      expect(tables_in(clone).first).to have_attributes(
        rows: table.rows, columns: table.columns, header_row: true, data: table.data
      )
    end

    it "isole les modifications ultérieures" do
      clone = challenge.new_clone
      clone.user = challenge.user
      clone.save!

      tables_in(clone).first.update!(data: { "0-0" => "chien" })

      expect(table.reload.cell(0, 0)).to eq("chat")
    end

    it "traite chaque tableau d'un même exercice" do
      second = Table.create!(rows: 1, columns: 1)
      attach(
        %(<action-text-attachment sgid="#{table.attachable_sgid}" content-type="application/octet-stream"></action-text-attachment>),
        %(<action-text-attachment sgid="#{second.attachable_sgid}" content-type="application/octet-stream"></action-text-attachment>)
      )

      expect { challenge.new_clone }.to change(Table, :count).by(2)
    end
  end

  describe "images" do
    let(:blob) do
      ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("image factice"), filename: "photo.png", content_type: "image/png"
      )
    end

    before do
      attach(%(<action-text-attachment sgid="#{blob.attachable_sgid}" content-type="image/png" filename="photo.png"></action-text-attachment>))
    end

    # Choix assumé : un blob est immuable, et Active Storage ne purge que ceux
    # devenus orphelins. Le dupliquer ne ferait que gonfler le stockage.
    it "laisse le clone partager le fichier de l'original" do
      clone = challenge.new_clone

      expect(clone.content.body.to_html).to include(blob.attachable_sgid)
    end

    it "ne crée aucun blob" do
      expect { challenge.new_clone }.not_to change(ActiveStorage::Blob, :count)
    end
  end

  describe "texte" do
    it "préserve les guillemets doubles rédigés par l'enseignant" do
      # L'ancienne version faisait `gsub('"', "'")` sur tout le corps.
      attach(%(<div>Il a dit "bonjour" puis "au revoir".</div>))

      expect(challenge.new_clone.content.body.to_html).to include(%(dit "bonjour"))
    end

    it "conserve un corps sans pièce jointe" do
      attach("<div>Une consigne simple</div>")

      expect(challenge.new_clone.content.body.to_html).to include("Une consigne simple")
    end

    it "accepte un exercice au contenu vide" do
      challenge.content = ""
      challenge.save!

      expect { challenge.new_clone }.not_to raise_error
    end
  end
end
