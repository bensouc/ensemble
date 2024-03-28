require 'rails_helper'

RSpec.describe "Skills", type: :request do
  describe "GET /index" do
    it "returns a success response" do
      get "/skills"
      expect(response).to have_http_status(:found)
    end
  end
end
