# frozen_string_literal: true

require "rails_helper"

# Un invité n'a ni prénom ni nom tant qu'il n'a pas accepté. Il ne se connecte
# pas encore, mais un admin peut le personnifier : le tableau de bord levait
# alors NoMethodError sur `first_name.capitalize`, et le bandeau de
# personnification affichait « Vous naviguez en tant que » suivi de rien.
RSpec.describe "Compte sans prénom", type: :request do
  let(:invite) do
    create(:user, admin: false).tap do |user|
      user.update_columns(first_name: nil, last_name: nil, email: "invite@exemple.fr")
    end
  end

  it "ouvre le tableau de bord en saluant par l'email" do
    sign_in invite

    get dashboard_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Bienvenue invite@exemple.fr")
  end

  it "nomme l'invité dans le bandeau de personnification" do
    admin = create(:user, admin: true, school: invite.school)
    sign_in admin
    post impersonation_path(invite)
    follow_redirect! while response.redirect?

    expect(response.body).to include("Vous naviguez en tant que <strong>invite@exemple.fr</strong>")
    expect(flash[:notice]).to eq("Vous naviguez maintenant en tant que invite@exemple.fr.")
  end
end
