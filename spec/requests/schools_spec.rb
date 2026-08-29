require 'rails_helper'

RSpec.describe "Schools", type: :request do
  describe "GET /show" do
    # `School.last` dépendait de ce que d'autres specs avaient laissé en base :
    # les blocs `before(:all)` échappent aux transactions, leurs données
    # survivent au passage, et selon l'ordre la table pouvait être vide — d'où
    # un `undefined method \`id\' for nil` intermittent.
    it "goes to the school show" do
      school = create(:school)
      get "/schools/#{school.id}"
      expect(response).to have_http_status(:found)
    end

  end
end
