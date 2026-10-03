# frozen_string_literal: true

# Messages d'Action Cable (Solid Cable), dans la base principale plutôt que dans
# la base « cable » à part que propose l'installateur. Repris de
# db/cable_schema.rb (solid_cable 4.1).
class CreateSolidCableMessages < ActiveRecord::Migration[7.2]
  def change
    create_table "solid_cable_messages" do |t|
      t.binary "channel", limit: 1024, null: false
      t.binary "payload", limit: 536870912, null: false
      t.datetime "created_at", null: false
      t.integer "channel_hash", limit: 8, null: false
      t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
      t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
    end
  end
end
