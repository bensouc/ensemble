# frozen_string_literal: true

require "rails_helper"

# Sans rails-ujs, les liens de suppression partent en vrai DELETE, envoyé par
# Turbo (`data-turbo-method`). Après un 302, le navigateur rejoue ce DELETE sur
# la page de destination — `DELETE /classrooms`, qui n'existe pas. Chaque action
# visée par un tel lien répond donc 303 : la destination se charge en GET.
RSpec.describe "Liens DELETE envoyés par Turbo", type: :request do
  let(:ecole) { create(:school) }
  let(:enseignant) { create(:user, school: ecole, admin: false) }
  let(:collegue) { create(:user, school: ecole, admin: false) }
  let(:classe) { create(:classroom, user: enseignant) }

  it "supprimer une classe" do
    sign_in enseignant

    delete classroom_path(classe)

    expect(response).to have_http_status(:see_other)
    expect(response).to redirect_to(classrooms_path)
  end

  it "supprimer un élève" do
    eleve = create(:student, classroom: classe)
    sign_in enseignant

    expect { delete student_path(eleve) }.to change(Student, :count).by(-1)
    expect(response).to have_http_status(:see_other)
  end

  it "retirer une classe partagée" do
    partage = create(:shared_classroom, user: collegue, classroom: classe)
    sign_in collegue

    expect { delete classroom_shared_classroom_path(classe, partage) }.to change(SharedClassroom, :count).by(-1)
    expect(response).to have_http_status(:see_other)
  end

  it "quitter une conversation" do
    conversation = Conversation.find_or_create_classic_conversation(enseignant, collegue)
    sign_in enseignant

    delete remove_user_conversation_path(conversation)

    expect(response).to have_http_status(:see_other)
    expect(conversation.users.reload).not_to include(enseignant)
  end

  it "se déconnecter" do
    sign_in enseignant

    delete destroy_user_session_path

    expect(response).to have_http_status(:see_other)
  end

  it "supprimer son compte" do
    sign_in enseignant

    expect { delete user_registration_path }.to change(User, :count).by(-1)
    expect(response).to have_http_status(:see_other)
  end
end
