# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkPlanSkill, type: :model do
  # Une école cohérente de bout en bout — enseignant, niveau, classe, domaine et
  # compétence. Les factories, laissées à elles-mêmes, donnent à l'élève un
  # niveau (donc une école, via `Student#school`) différent de celui de la
  # compétence : `Belt#belt_update_by_domain_and_level` ne trouve alors AUCUNE
  # compétence pour l'école de l'élève, en conclut que la ceinture est complète
  # et promeut tous ses Result en « ceinture validée ».
  #
  # Le domaine est nommé en dur pour la même raison : tiré au hasard, il tombe
  # parfois sur un domaine « spécial », dont les ceintures suivent une tout
  # autre règle (`Belt.update_special_belts_on_domain`).
  let(:school) { create(:school) }
  let(:user) { create(:user, school:) }
  let(:grade) { create(:grade, school:, name: "CM1", grade_level: "CM1") }
  let(:classroom) { create(:classroom, user:, grade:) }
  let(:student) { create(:student, classroom:) }
  let(:work_plan) { create(:work_plan, user:, student:, grade:) }
  let(:domain) { create(:domain, grade:, name: "Calcul", special: false) }
  let(:work_plan_domain) { create(:work_plan_domain, work_plan:, domain:, level: 1) }
  let(:skill) { create(:skill, domain:, level: 1, school:) }

  def new_exercice_wps
    WorkPlanSkill.new(skill:, work_plan_domain:, kind: "exercice", status: "new")
  end

  def existing_exercice_wps(challenge:, status:)
    WorkPlanSkill.create!(skill:, work_plan_domain:, kind: "exercice", status:, challenge:)
  end

  describe "#clone" do
    # Un plan de travail sans élève : `update_result` se retire alors dès sa
    # première ligne, et ce qui est vérifié ici reste `#clone` seul.
    let(:orphan_work_plan) { create(:work_plan, user:) }
    let(:source_domain) { create(:work_plan_domain, work_plan: orphan_work_plan) }
    let(:target_domain) { create(:work_plan_domain, work_plan: orphan_work_plan) }

    it "recopie la compétence et son exercice, et repart d'une ardoise propre" do
      challenge = create(:challenge, user:, skill:)
      source = WorkPlanSkill.create!(skill:, work_plan_domain: source_domain, kind: "exercice",
                                     status: "completed", challenge:, completed: true)

      source.clone(orphan_work_plan, target_domain)

      copy = target_domain.work_plan_skills.sole
      expect(copy).to have_attributes(skill:, challenge:, kind: "exercice", status: "new", completed: false)
    end

    it "ne réécrit pas la progression de l'élève à qui on donne la copie" do
      Result.create!(student:, skill:, status: "completed", kind: "exercice")
      source = WorkPlanSkill.create!(skill:, work_plan_domain: source_domain, kind: "exercice", status: "new")
      cible = create(:work_plan_domain, work_plan:) # ce plan de travail-ci a un élève

      source.clone(work_plan, cible)

      expect(Result.find_by(student:, skill:)).
        to have_attributes(status: "completed", kind: "exercice")
    end

    # `Result#kind` est l'étage de l'élève — jeu, exercice ou ceinture — et
    # `attach_next_skills` le lit pour décider quoi donner ensuite. Un « jeu »
    # posé à la main par l'enseignant n'existe nulle part ailleurs : sans ce
    # Result, la génération suivante repartirait sur « exercice ».
    it "pose le Result de l'élève qui n'en a pas encore sur la compétence" do
      source = WorkPlanSkill.create!(skill:, work_plan_domain: source_domain, kind: "jeu", status: "new")
      cible = create(:work_plan_domain, work_plan:, domain:, level: 1)

      source.clone(work_plan, cible)

      expect(Result.find_by(student:, skill:)).to have_attributes(kind: "jeu", status: "new")
    end

    # `update_column` fabrique ici ce qu'une vieille ligne de la base pourrait
    # être : un `kind` hors de la liste admise.
    it "lève au lieu de laisser une copie refusée disparaître sans bruit" do
      source = WorkPlanSkill.create!(skill:, work_plan_domain: source_domain, kind: "exercice", status: "new")
      source.update_column(:kind, "atelier")

      expect { source.reload.clone(orphan_work_plan, target_domain) }.
        to raise_error(ActiveRecord::RecordInvalid)
      expect(target_domain.work_plan_skills).to be_empty
    end
  end

  # Le `Result` suit l'état du WPS, mais il ne s'écrit que sur une sauvegarde :
  # l'écriture était accrochée à `after_validation`, donc à `valid?`.
  describe "la mise à jour du Result" do
    it "une évaluation met la progression de l'élève à jour" do
      wps = WorkPlanSkill.create!(skill:, work_plan_domain:, kind: "ceinture", status: "new")

      wps.update!(status: "completed")

      expect(Result.find_by(student:, skill:)).
        to have_attributes(status: "completed", kind: "ceinture")
    end

    it "poser une compétence dans un plan de travail pose son Result" do
      expect { WorkPlanSkill.create!(skill:, work_plan_domain:, kind: "exercice", status: "new") }.
        to change { Result.where(student:, skill:).count }.from(0).to(1)
    end

    # La ligne était insérée vide puis remplie aussitôt : deux écritures, donc
    # deux recomptages de ceinture, dont un sur un résultat sans nature.
    it "n'écrit la ligne qu'une fois quand elle n'existait pas" do
      ecritures = 0
      abonnement = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
        ecritures += 1 if payload[:sql].to_s.match?(/\A(INSERT INTO "results"|UPDATE "results")/)
      end

      WorkPlanSkill.create!(skill:, work_plan_domain:, kind: "exercice", status: "new")

      ActiveSupport::Notifications.unsubscribe(abonnement)
      expect(ecritures).to eq(1)
    end

    # Le pendant du garde-fou : hors évaluation, un acquis de ceinture ne bouge
    # pas. C'est ce qui protège l'élève quand on repose une compétence dans un
    # plan de travail, qu'on change son exercice ou qu'on copie un plan.
    it "poser une compétence dans un plan ne défait pas une ceinture acquise" do
      Result.create!(student:, skill:, kind: "ceinture", status: "completed")

      WorkPlanSkill.create!(skill:, work_plan_domain:, kind: "exercice", status: "new")

      expect(Result.find_by(student:, skill:)).
        to have_attributes(kind: "ceinture", status: "completed")
    end

    it "demander si un WPS est valide n'écrit rien" do
      wps = WorkPlanSkill.create!(skill:, work_plan_domain:, kind: "exercice", status: "new")
      Result.find_by(student:, skill:).update!(status: "completed", kind: "exercice")

      wps.valid?

      expect(Result.find_by(student:, skill:)).
        to have_attributes(status: "completed", kind: "exercice")
    end
  end

  describe "#get_challenge_4_wps" do
    it "prend le premier exercice de la compétence dans l'ordre des positions" do
      first_created = create(:challenge, user:, skill:)
      second_created = create(:challenge, user:, skill:)
      second_created.move_to_top

      expect(new_exercice_wps.get_challenge_4_wps).to eq(second_created)
      expect(second_created.position).to be < first_created.reload.position
    end

    it "saute les exercices que l'élève a déjà eus" do
      already_done = create(:challenge, user:, skill:)
      next_one = create(:challenge, user:, skill:)
      existing_exercice_wps(challenge: already_done, status: "completed")

      expect(new_exercice_wps.get_challenge_4_wps).to eq(next_one)
    end

    it "renvoie nil quand l'élève a eu tous les exercices de la compétence" do
      only_one = create(:challenge, user:, skill:)
      existing_exercice_wps(challenge: only_one, status: "completed")

      expect(new_exercice_wps.get_challenge_4_wps).to be_nil
    end

    it "ne crée plus d'exercice vide quand la liste est épuisée" do
      existing_exercice_wps(challenge: create(:challenge, user:, skill:), status: "completed")

      expect { new_exercice_wps.get_challenge_4_wps }.not_to change(Challenge, :count)
    end

    it "rejoue l'exercice du dernier plan de travail resté à faire" do
      not_done_yet = create(:challenge, user:, skill:)
      create(:challenge, user:, skill:)
      existing_exercice_wps(challenge: not_done_yet, status: "new")

      expect(new_exercice_wps.get_challenge_4_wps).to eq(not_done_yet)
    end

    it "ne plante pas quand le dernier plan de travail à faire n'a pas d'exercice" do
      available = create(:challenge, user:, skill:)
      existing_exercice_wps(challenge: nil, status: "new")

      expect(new_exercice_wps.get_challenge_4_wps).to eq(available)
    end

    it "ignore les exercices de ceinture" do
      create(:challenge, user:, skill:, for_belt: true)

      expect(new_exercice_wps.get_challenge_4_wps).to be_nil
    end

    it "ignore les exercices attribués à un autre élève" do
      other_student = create(:student, classroom:)
      other_wpd = create(:work_plan_domain, work_plan: create(:work_plan, user:, student: other_student))
      taken_by_other = create(:challenge, user:, skill:)
      WorkPlanSkill.create!(skill:, work_plan_domain: other_wpd, kind: "exercice",
                            status: "completed", challenge: taken_by_other)

      expect(new_exercice_wps.get_challenge_4_wps).to eq(taken_by_other)
    end
  end
end
