# frozen_string_literal: true

class Challenge < ApplicationRecord
  # Les exercices de ceinture et les exercices classiques forment deux listes
  # affichées séparément : sans `for_belt` dans le scope, un exercice de ceinture
  # intercalé ferait qu'un clic sur ⬆️ échange avec une ligne invisible.
  acts_as_list scope: [:skill_id, :for_belt]

  belongs_to :skill
  belongs_to :user
  has_rich_text :content
  has_many_attached :photos, dependent: :destroy
  has_one :school, through: :skill

  has_many :work_plan_skills, dependent: nil

  validates :name, presence: true, uniqueness: { message: "Le nom de cet exercice éxiste déja", scope: :skill }
  # `presence` rejette `false` autant que `nil` : la validation précédente
  # rendait donc impossible de dé-partager un exercice. Sans effet aujourd'hui
  # (les 2911 exercices sont à `true`), mais c'était un piège armé.
  validates :shared, inclusion: { in: [true, false] }

  scope :for_belt, -> { where(for_belt: true) }
  scope :classic, -> { where(for_belt: false) }
  scope :ordered, -> { order(:position) }

  def for_belt?
    for_belt == true
  end

  # `for_belt` est recopié : sans lui, cloner un exercice de ceinture en faisait un
  # exercice classique, qui changeait donc de liste.
  def new_clone
    Challenge.new(name: clone_name, content: cloned_content, skill_id:, for_belt:)
  end


  # CLASS METHOD

  # Exercices déjà attribués à cet élève sur cette compétence.
  #
  # Le filtre élève se faisait en Ruby après avoir chargé TOUS les WPS de la
  # compétence, tous élèves confondus — appelé une fois par compétence de chaque
  # domaine à la génération d'un plan de travail.
  def self.assigned_challenges(skill, student)
    joins(work_plan_skills: { work_plan_domain: :work_plan }).
      where(work_plan_skills: { skill_id: skill.id, kind: "exercice" },
            work_plans: { student_id: student&.id }).
      distinct
  end

  # Exercice vide, à rédiger, placé en fin de liste de la compétence par
  # acts_as_list. Déclenché par le bouton « Créer » de l'éditeur de plan de
  # travail quand l'élève a eu tous les exercices existants.
  #
  # Le nom doit être unique par compétence : celui construit sur `count + 1`
  # retombe sur un nom déjà pris dès qu'un exercice a été supprimé, et
  # l'enregistrement échouait alors en silence.
  def self.create_empty(skill, current_user)
    challenge = Challenge.new(skill:, name: empty_challenge_name(skill), user: current_user)
    challenge.content = "Exercice à REDIGER............................"
    challenge.save!
    challenge
  end

  def self.empty_challenge_name(skill)
    base = "#{skill.name} #{Challenge.classic.where(skill_id: skill.id).count + 1}-NEW"
    taken = Challenge.where(skill_id: skill.id).pluck(:name).to_set

    return base unless taken.include?(base)

    suffix = 2
    suffix += 1 while taken.include?("#{base}-#{suffix}")
    "#{base}-#{suffix}"
  end

  private

  # Suffixe déterministe plutôt que `rand(1..100)` : le nom est unique par
  # compétence, et deux clonages successifs pouvaient tirer le même nombre —
  # l'enregistrement échouait alors sans que l'utilisateur comprenne pourquoi.
  def clone_name
    base = "#{name}-Clone"
    taken = Challenge.where(skill_id: skill_id)
                     .where("name LIKE ?", "#{Challenge.sanitize_sql_like(base)}%")
                     .pluck(:name)
                     .to_set

    return base unless taken.include?(base)

    suffix = 2
    suffix += 1 while taken.include?("#{base}#{suffix}")
    "#{base}#{suffix}"
  end

  # Recopie le corps BRUT, en remplaçant chaque tableau par une copie fraîche.
  #
  # L'implémentation précédente travaillait sur `content.body.to_s`, qui REND et
  # sanitise le contenu : `action-text-attachment` n'étant pas dans la liste
  # blanche du sanitizer, la balise et son `content-type` disparaissaient. Le
  # garde `include?("application/octet-stream")` était donc toujours faux, et le
  # clonage des tableaux n'a jamais tourné. Conséquence observée en base : 20
  # tableaux référencés par plusieurs exercices, jusqu'à 6 pour un seul — éditer
  # une cellule depuis l'un modifiait silencieusement les autres.
  #
  # Elle remplaçait par ailleurs TOUS les guillemets doubles du corps par des
  # simples, y compris ceux du texte rédigé par l'enseignant.
  #
  # Les images restent volontairement partagées : un blob est immuable, et
  # Active Storage ne purge que ceux devenus orphelins — mesuré, supprimer un
  # exercice n'enfile aucune purge tant qu'une autre référence subsiste.
  def cloned_content
    html = content&.body&.to_html.to_s
    return html if html.blank?

    ActionText::Fragment.wrap(html).update do |source|
      source.css("action-text-attachment[sgid]").each do |node|
        table = table_for(node["sgid"])
        node["sgid"] = table.duplicate.attachable_sgid if table
      end
    end.to_html
  end

  # Deux formats de sgid coexistent en base (Base64(Marshal) pour les anciens,
  # Base64(JSON) pour les récents) : on laisse ActionText les vérifier plutôt
  # que de les décoder à la main.
  def table_for(sgid)
    Table.from_attachable_sgid(sgid)
  rescue ActiveRecord::RecordNotFound
    nil
  end
end
