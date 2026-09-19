# frozen_string_literal: true

class WorkPlanSkill < ApplicationRecord
  # Le `Result` d'un élève sur une compétence suit l'état de son WPS. C'était un
  # `after_validation` : la simple question « ce WPS est-il valide ? » écrivait
  # donc en base, et un `valid?` sans intention de sauvegarder remettait à « new »
  # une compétence acquise. `after_save` demande une sauvegarde pour écrire.
  #
  # (L'option `only:` qui accompagnait l'`after_validation` n'existe pas —
  # `after_validation` connaît `on:`. Elle était donc avalée sans bruit, et le
  # callback tournait de toute façon à chaque validation, création comprise.
  # Le comportement est conservé tel quel ici : `after_save` sans condition.)
  after_save :update_result, unless: :skip_result_update
  # after_destroy :reset_result

  # Cloner un plan de travail, c'est donner du travail à faire — pas évaluer
  # l'élève. Sans ce garde-fou, chaque copie réécrivait le `Result` de l'élève
  # cible : tout ce qu'il avait acquis à l'exercice repassait à « pas fait »,
  # et une compétence coûtait vingt requêtes au lieu de deux.
  attr_accessor :skip_result_update

  # Un acquis de ceinture ne se défait pas par accident : poser une compétence
  # dans un plan de travail, changer son exercice ou copier un plan ne doivent
  # pas y toucher. Seule l'évaluation fait autorité — c'est l'enseignant qui
  # revient sur ce qu'il a lui-même saisi, et le corriger de « réussi » à
  # « raté » restait sans effet : le résultat et la ceinture tenaient bon.
  #
  # Posé par `WorkPlanSkillsController#eval_update`, le seul écran dont c'est
  # le propos.
  attr_accessor :evaluating

  belongs_to :work_plan_domain
  acts_as_list scope: :work_plan_domain
  include Positionable

  belongs_to :skill
  belongs_to :challenge, optional: true
  # belongs_to :student, optional: true
  has_one :student, through: :work_plan_domain
  has_one :work_plan, through: :work_plan_domain

  validates :kind, presence: true, inclusion: { in: %w[jeu exercice controle ceinture] }
  validates :status, inclusion: { in: %w[redo failed redo_OK completed new] }

  # def student
  #   return super unless association(:work_plan_domain).loaded? &&
  #                       work_plan_domain.association(:work_plan).loaded?

  #   work_plan_domain.work_plan.student
  # end
  def completed?
    completed == true
  end

  def special_wps?
    work_plan_domain.work_plan.special_wps?
  end

  # `save!` et non `save` : une copie refusée par les validations disparaissait
  # sans bruit, et l'enseignant récupérait un plan de travail amputé d'une
  # compétence sans rien pour le lui dire. Le reste du clonage lève déjà
  # (`WorkPlan.create!` puis `new_wp.save!` dans `WorkPlansController#clone`).
  #
  # La position n'est pas recopiée : acts_as_list l'écrase en `before_create`
  # puisque le domaine — donc le scope de la liste — change. C'est l'ordre
  # d'itération de l'appelant qui fait l'ordre du clone.
  def clone(_current_wp, new_wp_domain)
    new_wps = dup
    new_wps.work_plan_domain_id = new_wp_domain.id
    # new_wps.student = student
    new_wps.status = "new"
    new_wps.completed = false
    new_wps.skip_result_update = result_deja_pose?(new_wp_domain)
    new_wps.save!
  end

  # Exercice à attacher à ce WPS : le premier de la compétence que l'élève n'a pas
  # encore eu, dans l'ordre choisi par l'enseignant (`Challenge#position`).
  #
  # Renvoie `nil` quand la liste est épuisée. On ne fabrique plus d'exercice vide
  # en silence : l'éditeur de plan de travail propose alors à l'enseignant de
  # reprendre un exercice existant ou d'en créer un.
  def get_challenge_4_wps
    last_wps = last_exercice_wps_for_student
    # exercice pas encore fait : on rejoue le même
    return last_wps.challenge if last_wps&.status == "new" && last_wps.challenge.present?

    Challenge.classic.
      where(skill_id: skill_id).
      where.not(id: Challenge.assigned_challenges(skill, student)).
      ordered.
      first
  end

  def self.last_4_wps(_work_plan, wps, current_student)
    # retrieve the last 4 wps for the student on this skill ids
    out = WorkPlanSkill.includes([:skill, { work_plan_domain: :student }]).where(skill_id: wps.skill_id)
    out = out.select { |work_plan_skill| work_plan_skill.student == current_student }.sort_by(&:created_at).reverse
    out.reject { |t| t == wps }
    out.last(3)
  end

  def self.last_wps(student, skills)
    # wpss = student.work_plan_skills.where(skill: skills) # get all wps on skills and student
    # wpss.group_by(&:skill_id).transform_values { |wps_s| wps_s.max_by(&:updated_at) }.values.sort_by(&:updated_at)
    student.work_plan_skills.
      where(skill: skills).
      select("DISTINCT ON (work_plan_skills.skill_id) work_plan_skills.*").
      order("work_plan_skills.skill_id, work_plan_skills.updated_at DESC").
      order("work_plan_skills.updated_at")
  end

  def attach_content(result)
    if result.nil? || result.kind.nil?
      self.challenge = get_challenge_4_wps
      save!
      # If the previous WorkPlanSkill is completed, create a new WorkPlanSkill of the appropriate kind and save it
    elsif result.status == "completed"
      case result.kind
      when "jeu"
        self.kind = "exercice"
        self.challenge = get_challenge_4_wps
      when "exercice"
        self.kind = "ceinture"
      end
      save!
      # If the previous WorkPlanSkill is not completed, create a new WorkPlanSkill of the appropriate kind and save it
    elsif %w[redo failed redo_OK new].include?(result.status)
      self.kind = result.kind
      self.kind = "exercice" if result.kind == "ceinture" && result.status != "new"
      self.challenge = get_challenge_4_wps if kind == "exercice"
      save!
    end
  end

  private

  # Le clone pose le `Result` quand l'élève n'en a aucun sur la compétence, et
  # ne touche à rien sinon.
  #
  # `Result#kind` n'est pas un drapeau de ceinture : c'est l'étage de l'élève —
  # jeu, exercice ou ceinture — et `attach_next_skills` le lit pour décider quoi
  # donner ensuite. Écrire par-dessus un résultat existant effaçait donc ce que
  # l'élève avait acquis ; ne jamais écrire perdait l'étage d'un WPS « jeu »
  # posé à la main, et la génération suivante repartait sur « exercice ».
  def result_deja_pose?(new_wp_domain)
    eleve = new_wp_domain.student
    return true if eleve.nil?

    Result.exists?(student: eleve, skill_id:)
  end

  # Dernier exercice de cet élève sur cette compétence. Le filtre élève se faisait
  # en Ruby après avoir chargé TOUS les WPS de la compétence, tous élèves
  # confondus.
  def last_exercice_wps_for_student
    WorkPlanSkill.joins(work_plan_domain: :work_plan).
      where(skill_id: skill_id, kind: "exercice", work_plans: { student_id: student&.id }).
      where.not(id: id).
      order(:created_at, :id).
      last
  end

  # `find_or_initialize_by` et non `find_or_create_by` : la version précédente
  # insérait une ligne vide, puis la remplissait aussitôt. Deux écritures, donc
  # deux passages dans `Result#belt_update_by_domain_and_level`, qui recompte
  # tout le domaine et décroche ou repose la ceinture à chaque fois. Le premier
  # de ces deux passages voyait un résultat sans nature ni statut : un état qui
  # n'a jamais existé pour l'enseignant.
  #
  # Une ceinture déjà validée n'est pas redescendue — c'est le seul acquis que
  # l'état d'un plan de travail ne peut pas défaire. Le test tombe forcément à
  # faux sur un résultat qui vient d'être initialisé, dont la nature est `nil` :
  # celui-là est donc bien écrit.
  def update_result
    return if work_plan_domain.student.nil?

    result = Result.find_or_initialize_by(student:, skill:)
    return if result.belt_validated? && !evaluating

    result.update!(status:, kind:, origin: Result::EVALUATION)
  end

  def reset_result
    return unless special_wps?

    # find_or_create results
    result = Result.find_or_create_by(student:, skill:)
    # update results
    result.update!(status: "new", kind:)
  end
end
