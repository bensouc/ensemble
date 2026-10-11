# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("lib/cache_des_assets")

RSpec.describe CacheDesAssets do
  def entetes(chemin, status: 200)
    app = ->(_env) { [status, { "content-type" => "text/css" }, ["ok"]] }
    described_class.new(app).call(Rack::MockRequest.env_for(chemin))[1]
  end

  it "garde un an en cache un fichier compilé, à empreinte" do
    expect(entetes("/assets/application-4ef7f4f5.css")["cache-control"]).to eq("public, max-age=31536000, immutable")
    expect(entetes("/assets/fontawesome/fa-solid-900-1a2b3c4d.woff2")["cache-control"]).to include("immutable")
  end

  it "ne touche ni au reste de public/, ni à une page, ni à une réponse en erreur" do
    expect(entetes("/favicon.ico")["cache-control"]).to be_nil
    expect(entetes("/service-worker.js")["cache-control"]).to be_nil
    expect(entetes("/assets/application.css")["cache-control"]).to be_nil
    expect(entetes("/assets/application-4ef7f4f5.css", status: 404)["cache-control"]).to be_nil
  end
end
