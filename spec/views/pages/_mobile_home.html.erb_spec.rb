# frozen_string_literal: true

require "rails_helper"

# Le jumeau mobile du bouton « Accéder aux tutos » : même URL recopiée, même
# fragilité. Voir `spec/views/pages/_details.html.erb_spec.rb`.
#
# Décrit par son chemin de vue, et pas par une phrase : sans ça,
# `lookup_context.prefixes` reste vide et le `render 'pop_up_pwa_install'` de la
# première ligne est cherché à la racine.
RSpec.describe "pages/_mobile_home", type: :view do
  # Ce partiel-là interroge Devise, absent d'un spec de vue.
  before do
    without_partial_double_verification do
      allow(view).to receive(:user_signed_in?).and_return(false)
      allow(view).to receive(:current_user).and_return(nil)
    end
  end

  it "mène au sommaire des tutos" do
    render partial: "pages/mobile_home"

    expect(rendered).to include("href=\"#{ApplicationHelper::TUTO_SOMMAIRE}\"")
    expect(rendered).to include("Accéder aux tutos")
  end
end
