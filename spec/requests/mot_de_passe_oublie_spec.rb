# frozen_string_literal: true

require "rails_helper"

# Devise répondait ses échecs en 200, et Turbo n'affiche pas un formulaire
# renvoyé en 200 : sur un e-mail inconnu, la page restait muette.
RSpec.describe "Mot de passe oublié", type: :request do
  it "réaffiche le formulaire et son erreur sur un e-mail inconnu, en 422 pour que Turbo l'affiche" do
    post user_password_path, params: { user: { email: "inconnu@exemple.fr" } }

    expect(response).to have_http_status(:unprocessable_content)
    expect(Nokogiri::HTML(response.body).at_css("input[name='user[email]'].is-invalid")).to be_present
  end
end
