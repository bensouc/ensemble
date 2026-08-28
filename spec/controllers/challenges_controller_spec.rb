# frozen_string_literal: true

require "rails_helper"
RSpec.describe ChallengesController, type: :controller do
  let(:user) { create(:user) }
  let(:challenge) { create(:challenge, user:) }
  let(:classroom) { create(:classroom, user:) }
  let(:student) { create(:student, classroom:) }
  let(:work_plan) { create(:work_plan, user:, student:) }
  let(:skill) { create(:skill, school: user.school) }
  let(:work_plan_domain) { create(:work_plan_domain, work_plan:) }
  let(:work_plan_skill) { create(:work_plan_skill, work_plan_domain:, kind: "exercice", challenge:) }
  describe "#index" do
    context "when user is not signed in" do
      it "returns a failure response" do
        get :index
        expect(response).not_to be_successful
      end
    end
    context "when user is signed in and has a classroom" do
      it "returns a successful response" do
        2.times do
          create(:challenge, user:)
        end
        sign_in(user)
        create(:classroom, user:)
        get :index
        expect(response).to be_successful
      end
    end
    context "when user is signed in and has no classroom" do
      it "redirect to classroom index" do
        2.times do
          create(:challenge, user:)
        end
        sign_in(user)
        get :index
        expect(response).to redirect_to("http://test.host/classrooms")
      end
    end
    context "when user use filters" do
      it "returns a successful response" do
        sign_in(user)
        get :index, params: { "/challenges" => { grade: skill.domain.grade, domain: skill.domain , level: skill.level } }
        # expect(response).to be_successful
        expect(response).to redirect_to("http://test.host/classrooms")
      end
    end
  end

  describe "#show" do
    context "when user is not signed in" do
      it "returns a failure response" do
        get :show, params: { id: challenge.id }
        expect(response).not_to be_successful
      end
    end

    context "when user is signed in" do
      it "returns a successful response" do
        sign_in(user)
        get :show, params: { id: challenge.id }
        expect(response).to be_successful
      end
    end
  end

  describe "#new" do
    context "when user is not signed in" do
      it "returns a failure response" do
        get :new
        expect(response).not_to be_successful
      end
    end
    context "when user is signed in" do
      it "returns a successful response with the skill params" do
        sign_in(user)
        get :new, params: { skill: skill.id }
        expect(response).to be_successful
        expect(response).to render_template(:new)
      end
    end
  end

  describe "#edit" do
    context "when user is not signed in" do
      it "returns a failure response" do
        get :edit, params: { id: challenge.id }
        expect(response).not_to be_successful
      end
    end
    context "when user is signed in" do
      it "returns a successful response with the skill params" do
        sign_in(user)
        get :edit, params: { id: challenge.id }
        expect(response).to be_successful
        expect(response).to render_template(:edit)
      end
    end
  end

  describe "#create" do
    context "when user is not signed in" do
      it "returns a failure response" do
        post :create, params: { challenge: { name: "test" } }
        expect(response).not_to be_successful
      end
    end
    context "when user is signed in" do
      it "creates a new challenge and redirect to It" do
        sign_in(user)
        expect {
          post :create, params: { challenge: {
                          skill_id: skill.id,
                          content: Faker::Lorem.paragraph(sentence_count: 2, supplemental: false, random_sentences_to_add: 4),
                          name: Faker::Lorem.sentence(word_count: 3, supplemental: false, random_words_to_add: 4),
                        } }
        }.to change { Challenge.count }.by(1)
        expect(response).to redirect_to("http://test.host/challenges/#{Challenge.last.id}")
      end
    end
  end

  describe "#update" do
    context "when user is not signed in" do
      it "returns a failure response" do
        new_content = Faker::Lorem.paragraph(sentence_count: 2, supplemental: false, random_sentences_to_add: 4)
        new_name = Faker::Lorem.sentence(word_count: 3, supplemental: false, random_words_to_add: 4)
        patch :update, params: { id: challenge.id, challenge: {
                         content: new_content,
                         name: new_name,
                       } }
        expect(response).not_to be_successful
      end
    end
    context "when user is signed in" do
      it "update a sepcified challenge and redirect to It" do
        sign_in(user)
        new_content = "new-content"
        new_name = "new-name"
        patch :update, params: { id: challenge.id, challenge: {
                         content: new_content,
                         name: new_name,
                       } }
        challenge.reload
        expect(challenge.name).to eq(new_name)
        expect(response).to redirect_to(challenge_path(challenge))
      end
    end
  end

  describe "#clone" do
    context "when user is not signed in" do
      it "returns a failure response" do
        post :clone, params: { id: challenge.id, work_plan_skill_id: work_plan_skill }
        expect(response).not_to be_successful
      end
    end
    context "when user is signed in" do
      it "creates a new IDENTICAL challenge and redirect to It" do
        sign_in(user)
        # post "/challenges/:id", to: "challenges#clone"
        post :clone, params: { id: challenge.id, work_plan_skill_id: work_plan_skill }
        expect(Challenge.last.content.body).to eq(challenge.content.body)
        work_plan_skill.reload
        expect(work_plan_skill.challenge).to eq(Challenge.last)
        # expect(response).to render_template(["action_text/contents/_content", "layouts/action_text/contents/_content"])
        # expect(response).to render_template(:new)
      end
    end
  end

  describe "#destroy" do
    context "when user is not signed in" do
      it "returns a failure response" do
        delete :destroy, params: { id: challenge.id }
        expect(response).not_to be_successful
      end
    end
    context "when user is signed in" do
      it "destroy a sepcified challenge and redirect to It" do
        sign_in(user)
        chal = create(:challenge, user:)
        expect do
          delete :destroy, params: { id: chal.id }
        end.to change { Challenge.all.count }.by(-1)
        expect(response).to redirect_to(challenges_path)
      end
    end
  end

  describe "#index, ordre des exercices" do
    render_views

    it "affiche la position et les flèches de chaque exercice de la compétence" do
      grade = create(:grade, school: user.school)
      create(:classroom, user:, grade:)
      domain = create(:domain, grade:)
      ordered_skill = create(:skill, school: user.school, domain:, level: 1)
      first = create(:challenge, user:, skill: ordered_skill)
      second = create(:challenge, user:, skill: ordered_skill)
      sign_in(user)

      get :index

      expect(response.body).to include(transfer_challenge_path(first, direction: "down"))
      expect(response.body).to include(transfer_challenge_path(second, direction: "up"))
      # pas de flèche vers le haut sur le premier, ni vers le bas sur le dernier
      expect(response.body).not_to include(transfer_challenge_path(first, direction: "up"))
      expect(response.body).not_to include(transfer_challenge_path(second, direction: "down"))
      expect(response.body.index(first.name)).to be < response.body.index(second.name)
    end
  end

  describe "#duplicate" do
    render_views

    let(:ordered_skill) { create(:skill, school: user.school) }
    let!(:first) { create(:challenge, user:, skill: ordered_skill) }
    let!(:second) { create(:challenge, user:, skill: ordered_skill) }

    context "when user is not signed in" do
      it "returns a failure response" do
        post :duplicate, params: { id: first.id }
        expect(response).not_to be_successful
      end
    end

    context "when user is signed in" do
      before { sign_in(user) }

      it "place la copie en dernière position de la compétence" do
        expect do
          post :duplicate, params: { id: first.id }, format: :turbo_stream
        end.to change(Challenge, :count).by(1)

        copy = Challenge.last
        expect(copy.skill).to eq(ordered_skill)
        expect(copy.position).to eq(3)
        expect(copy.name).to start_with(first.name)
        expect(copy.user).to eq(user)
      end

      it "garde la nature de l'original" do
        belt = create(:challenge, user:, skill: ordered_skill, for_belt: true)

        post :duplicate, params: { id: belt.id }, format: :turbo_stream

        # sans ça, un exercice de ceinture cloné changeait de liste
        expect(Challenge.last).to be_for_belt
      end

      it "re-rend la liste avec la copie à la fin" do
        post :duplicate, params: { id: first.id }, format: :turbo_stream

        expect(response.body).to include("skill_#{ordered_skill.id}_challenges_list")
        expect(response.body.index(second.name)).to be < response.body.index(Challenge.last.name)
      end

      it "désigne la copie pour que le navigateur y descende" do
        # elle atterrit en dernière position, donc hors écran dès que la compétence
        # compte quelques exercices
        post :duplicate, params: { id: first.id }, format: :turbo_stream

        # une seule ligne est désignée, et c'est celle qui suit les exercices existants
        expect(response.body.scan('data-controller="reveal"').size).to eq(1)
        expect(response.body.index('data-controller="reveal"')).to be > response.body.index(second.name)
      end
    end
  end

  describe "les flux Turbo re-rendent la liste ordonnée" do
    render_views

    let(:ordered_skill) { create(:skill, school: user.school) }
    let!(:first) { create(:challenge, user:, skill: ordered_skill) }

    before { sign_in(user) }

    it "à la création, ajoute le nouvel exercice en fin de liste" do
      post :create,
           params: { challenge: { skill_id: ordered_skill.id, name: "Nouvel exo", content: "énoncé" } },
           format: :turbo_stream

      expect(response.body).to include("skill_#{ordered_skill.id}_challenges_list")
      expect(response.body.index(first.name)).to be < response.body.index("Nouvel exo")
      expect(Challenge.last.position).to eq(2)
    end

    it "à la suppression, renumérote la liste affichée" do
      second = create(:challenge, user:, skill: ordered_skill)

      delete :destroy, params: { id: first.id }, format: :turbo_stream

      expect(response.body).to include("skill_#{ordered_skill.id}_challenges_list")
      expect(response.body).to include(second.name)
      expect(second.reload.position).to eq(1)
    end
  end

  describe "la gouttière de tri vit hors de la frame de l'exercice" do
    render_views

    let(:ordered_skill) { create(:skill, school: user.school) }
    let!(:first) { create(:challenge, user:, skill: ordered_skill) }
    let!(:second) { create(:challenge, user:, skill: ordered_skill) }

    before { sign_in(user) }

    it "rend la gouttière avant la frame, dans l'index" do
      grade = create(:grade, school: user.school)
      create(:classroom, user:, grade:)
      domain = create(:domain, grade:)
      ordered_skill.update!(domain:, level: 1)

      get :index

      gutter = response.body.index("challenge-order")
      frame = response.body.index("<turbo-frame id=\"challenge_#{first.id}\"")
      expect(gutter).to be < frame
    end

    it "ne renvoie que la frame et le formulaire à l'édition" do
      get :edit, params: { id: first.id }

      expect(response.body).to include("cont-challenge")
      expect(response.body).not_to include("challenge-order")
    end

    it "ne renvoie que la frame après l'enregistrement" do
      patch :update, params: { id: first.id, challenge: { name: "nouveau nom" } }, format: :turbo_stream

      expect(response.body).to include("challenge_#{first.id}")
      expect(response.body).not_to include("challenge-order")
    end
  end

  describe "#move" do
    render_views

    let(:ordered_skill) { create(:skill, school: user.school) }
    let!(:first) { create(:challenge, user:, skill: ordered_skill) }
    let!(:second) { create(:challenge, user:, skill: ordered_skill) }

    context "when user is not signed in" do
      it "returns a failure response" do
        patch :move, params: { id: second.id, direction: "up" }
        expect(response).not_to be_successful
      end
    end

    context "when user is signed in" do
      before { sign_in(user) }

      it "fait remonter l'exercice d'un cran" do
        patch :move, params: { id: second.id, direction: "up" }, format: :turbo_stream

        expect([first.reload.position, second.reload.position]).to eq([2, 1])
      end

      it "fait descendre l'exercice d'un cran" do
        patch :move, params: { id: first.id, direction: "down" }, format: :turbo_stream

        expect([first.reload.position, second.reload.position]).to eq([2, 1])
      end

      it "re-rend la liste ordonnée de la compétence" do
        patch :move, params: { id: second.id, direction: "up" }, format: :turbo_stream

        expect(response.body).to include("skill_#{ordered_skill.id}_challenges_list")
        expect(response.body.index(second.name)).to be < response.body.index(first.name)
      end

      it "ne touche pas aux exercices d'une autre compétence" do
        other = create(:challenge, user:, skill: create(:skill, school: user.school))

        patch :move, params: { id: second.id, direction: "up" }, format: :turbo_stream

        expect(other.reload.position).to eq(1)
      end
    end
  end

  describe "#display_challenges" do
    it "renders caroussel of  XXX challenges" do
      sign_in(user)
      3.times do
        create(:challenge, user:, skill: challenge.skill)
      end
      p Challenge.where(skill: challenge.skill).count
      get :display_challenges, params: { id: challenge.id, work_plan_skill_id: work_plan_skill.id }
      expect(response).to render_template("challenges/_challenges_carroussel")
    end
    it "render the challenge if it is the only one for its skill" do
      sign_in(user)
      get :display_challenges, params: { id: challenge.id, work_plan_skill_id: work_plan_skill.id }
      expect(response).to render_template("challenges/_challenge")
    end
  end
  # Déplacer un exercice sous une autre compétence du MÊME domaine.
  describe "#transfer" do
    let(:domain) { create(:domain) }
    let(:depart) { create(:skill, domain:, school: user.school, level: 3) }
    let(:arrivee) { create(:skill, domain:, school: user.school, level: 3) }
    let!(:exercice) { create(:challenge, user:, skill: depart) }

    before { sign_in user }

    it "range l'exercice sous la compétence choisie" do
      patch :transfer, params: { id: exercice.id, skill_id: arrivee.id }

      expect(exercice.reload.skill).to eq(arrivee)
    end

    it "dit où il est parti — la compétence d'arrivée est souvent hors de l'écran" do
      patch :transfer, params: { id: exercice.id, skill_id: arrivee.id }

      expect(flash[:notice]).to include(arrivee.name)
    end

    it "donne l'exercice au prof qui le déplace" do
      autre_auteur = create(:user)
      exercice.update!(user: autre_auteur)

      patch :transfer, params: { id: exercice.id, skill_id: arrivee.id }

      expect(exercice.reload.user).to eq(user)
    end

    # Le compteur d'exercices de la compétence quittée doit tomber, sinon il
    # annonce un exercice qui n'y est plus.
    it "rafraîchit la compétence quittée" do
      autre = create(:challenge, user:, skill: depart)

      patch :transfer, params: { id: exercice.id, skill_id: arrivee.id }, format: :turbo_stream

      frame = assigns(:frames).find { |f| f[:liste_id].include?("skill_#{depart.id}_") }
      expect(frame[:compte]).to eq(1)
      expect(frame[:challenges]).to contain_exactly(autre)
    end

    # L'arrivée n'est à l'écran que si elle porte la MÊME ceinture : le filtre de
    # l'index porte dessus. Son compteur restait sinon figé sur l'ancien nombre.
    it "rafraîchit aussi la compétence d'arrivée quand elle est à l'écran" do
      patch :transfer, params: { id: exercice.id, skill_id: arrivee.id }, format: :turbo_stream

      cibles = assigns(:frames).map { |f| f[:liste_id] }
      expect(cibles).to include("skill_#{depart.id}_challenges_list", "skill_#{arrivee.id}_challenges_list")
    end

    it "ne rafraîchit que la compétence quittée quand l'arrivée est sur une autre ceinture" do
      ailleurs = create(:skill, domain:, school: user.school, level: 6)

      patch :transfer, params: { id: exercice.id, skill_id: ailleurs.id }, format: :turbo_stream

      expect(assigns(:frames).map { |f| f[:liste_id] }).to eq(["skill_#{depart.id}_challenges_list"])
    end

    # Le domaine ne se choisit pas dans la modale : une compétence d'ailleurs ne
    # peut arriver que par un paramètre forgé.
    it "refuse une compétence d'un autre domaine" do
      ailleurs = create(:skill, domain: create(:domain), school: user.school, level: 3)

      patch :transfer, params: { id: exercice.id, skill_id: ailleurs.id }

      expect(exercice.reload.skill).to eq(depart)
    end

    it "refuse de déplacer vers sa propre compétence" do
      patch :transfer, params: { id: exercice.id, skill_id: depart.id }

      expect(flash[:alert]).to be_present
    end

    it "refuse un exercice déjà utilisé dans un plan de travail" do
      create(:work_plan_skill, challenge: exercice, skill: depart, work_plan_domain:)

      patch :transfer, params: { id: exercice.id, skill_id: arrivee.id }

      expect(exercice.reload.skill).to eq(depart)
    end
  end

  describe "#transfer_form" do
    let(:domain) { create(:domain) }
    let(:depart) { create(:skill, domain:, school: user.school, level: 3) }
    let!(:exercice) { create(:challenge, user:, skill: depart) }

    before { sign_in user }

    it "propose les compétences de la ceinture demandée, dans le même domaine" do
      voisine = create(:skill, domain:, school: user.school, level: 5)
      create(:skill, domain: create(:domain), school: user.school, level: 5)

      get :transfer_form, params: { id: exercice.id, level: 5 }

      expect(assigns(:skills)).to contain_exactly(voisine)
    end

    # `.sort` triait par ID — ActiveRecord compare les clés primaires — donc dans
    # l'ordre de création. Ce doit être celui de la progression.
    it "les range dans l'ordre de leur position, pas de leur création" do
      derniere = create(:skill, domain:, school: user.school, level: 3, name: "en dernier")
      premiere = create(:skill, domain:, school: user.school, level: 3, name: "en premier")
      derniere.update_column(:position, 9)
      premiere.update_column(:position, 1)

      get :transfer_form, params: { id: exercice.id, level: 3 }

      expect(assigns(:skills).map(&:name)).to eq(["en premier", "en dernier"])
    end

    # Se déplacer vers là où l'on est déjà n'a pas de sens : on ne le propose pas.
    it "n'offre pas la compétence de départ" do
      get :transfer_form, params: { id: exercice.id, level: 3 }

      expect(assigns(:skills)).not_to include(depart)
    end
  end
end
