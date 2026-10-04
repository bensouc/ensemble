# frozen_string_literal: true

require "rails_helper"

# Une conversation se lit entre ses participants, et l'on n'écrit qu'à ses
# collègues — la messagerie est celle de l'école. Trois portes restaient
# ouvertes : `?conversation_id=` affichait n'importe quelle conversation (et la
# marquait lue), `contact_user` en ouvrait une avec n'importe quel compte, et
# `add_user` y faisait entrer n'importe qui.
RSpec.describe "Droits sur les conversations", type: :request do
  let(:ecole) { create(:school) }
  let(:enseignante) { create(:user, school: ecole, admin: false, first_name: "Alice") }
  let(:collegue) { create(:user, school: ecole, admin: false, first_name: "Bruno") }
  let!(:conversation) do
    Conversation.find_or_create_classic_conversation(enseignante, collegue).tap do |conversation|
      Message.create!(conversation:, user: enseignante, content: "Conseil de cycle jeudi")
    end
  end

  let(:intrus) { create(:user, admin: false) }

  def conversations_avec(utilisateur)
    Conversation.classic.joins(:users).where(users: { id: utilisateur.id })
  end

  context "pour un enseignant d'une autre école" do
    before { sign_in intrus }

    it "ne lit pas la conversation" do
      get conversations_path, params: { conversation_id: conversation.id }

      expect(response.body).not_to include("Conseil de cycle jeudi")
    end

    it "n'ouvre pas de conversation avec une enseignante d'une autre école" do
      expect { post contact_user_conversations_path(contact_id: enseignante.id) }.
        not_to change { conversations_avec(enseignante).count }
    end
  end

  it "n'ajoute pas un enseignant d'une autre école à une conversation" do
    sign_in collegue

    post add_user_conversation_path(conversation, new_user_id: intrus.id)

    expect(conversation.reload.users).not_to include(intrus)
  end

  context "entre collègues de l'école" do
    before { sign_in enseignante }

    it "lit la conversation" do
      get conversations_path, params: { conversation_id: conversation.id }

      expect(response.body).to include("Conseil de cycle jeudi")
    end

    it "ouvre une conversation avec un collègue" do
      autre = create(:user, school: ecole, admin: false)

      expect { post contact_user_conversations_path(contact_id: autre.id) }.
        to change { conversations_avec(autre).count }.by(1)
    end

    it "ajoute un collègue à la conversation" do
      autre = create(:user, school: ecole, admin: false)

      post add_user_conversation_path(conversation, new_user_id: autre.id)

      expect(conversation.reload.users).to include(autre)
    end
  end

  context "pour un admin d'une autre école" do
    before { sign_in create(:user, admin: true) }

    it "lit la conversation" do
      get conversations_path, params: { conversation_id: conversation.id }

      expect(response.body).to include("Conseil de cycle jeudi")
    end

    it "écrit à un enseignant de n'importe quelle école" do
      expect { post contact_user_conversations_path(contact_id: enseignante.id) }.
        to change { conversations_avec(enseignante).count }.by(1)
    end

    it "ajoute n'importe quel compte à une conversation" do
      post add_user_conversation_path(conversation, new_user_id: intrus.id)

      expect(conversation.reload.users).to include(intrus)
    end
  end
end
