# frozen_string_literal: true

require "rails_helper"

# Renommer une classe : son enseignant, les collègues du partage, les admins —
# ceux qui la voient dans leur liste. Le contrôleur sautait l'autorisation, et
# n'importe quel enseignant connecté renommait la classe d'une autre école en
# donnant son id.
RSpec.describe "Droits sur les classes", type: :request do
  let(:ecole) { create(:school) }
  let(:enseignant) { create(:user, school: ecole, admin: false) }
  let(:classe) { create(:classroom, user: enseignant, name: "CE1 A") }

  def renommer(nom)
    patch classroom_path(classe), params: { classroom: { name: nom } }
    classe.reload.name
  end

  it "refuse à un enseignant d'une autre école" do
    sign_in create(:user, admin: false)

    expect(renommer("Piratée")).to eq("CE1 A")
  end

  it "refuse à un collègue de l'école à qui la classe n'est pas partagée" do
    sign_in create(:user, school: ecole, admin: false)

    expect(renommer("Piratée")).to eq("CE1 A")
  end

  it "laisse l'enseignant de la classe la renommer" do
    sign_in enseignant

    expect(renommer("CE1 Les loutres")).to eq("CE1 Les loutres")
  end

  it "laisse un collègue du partage la renommer" do
    collegue = create(:user, school: ecole, admin: false)
    create(:shared_classroom, user: collegue, classroom: classe)
    sign_in collegue

    expect(renommer("CE1 Les loutres")).to eq("CE1 Les loutres")
  end
end
