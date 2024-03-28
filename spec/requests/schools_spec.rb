require 'rails_helper'

RSpec.describe "Schools", type: :request do
  describe "GET /show" do
    it "goes to the school show" do
      school = School.last
      get "/schools/#{school.id}"
      expect(response).to have_http_status(:found)
    end

  end
end
