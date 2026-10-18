# frozen_string_literal: true

class Challenge < ApplicationRecord
  # Les exercices de ceinture et les exercices classiques forment deux listes
  # affichées séparément : sans `for_belt` dans le scope, un exercice de ceinture
  # intercalé ferait qu'un clic sur ⬆️ échange avec une ligne invisible.
  acts_as_list scope: [:skill_id, :for_belt]
  include Positionable

  belongs_to :skill
  # Un exercice survit au départ de son auteur : c'est son grade, via la
  # compétence, qui le rattache à l'école. Sans `optional`, la nullification à la
  # suppression du compte passerait (elle écrit en `update_all`) mais le moindre
  # enregistrement ultérieur de l'exercice échouerait sur « User must exist ».
  belongs_to :user, optional: true
  has_rich_text :content
  has_many_attached :photos, dependent: :destroy
  has_one :school, through: :skill

  has_many :work_plan_skills, dependent: nil
  # Un exercice supprimé laisse la ligne de fiche sans exercice, à recharger.
  has_many :belt_sheet_skills, dependent: :nullify

  # Unique par compétence ET par liste : un exercice de ceinture peut porter le
  # nom d'un exercice de plan de travail (index unique en base, même portée).
  validates :name, presence: true,
                   uniqueness: { message: "est déjà utilisé pour cette compétence", scope: %i[skill_id for_belt] }
  # `presence` rejette `false` autant que `nil` : la validation précédente
  # rendait donc impossible de dé-partager un exercice. Sans effet aujourd'hui
  # (les 2911 exercices sont à `true`), mais c'était un piège armé.
  validates :shared, inclusion: { in: [true, false] }

  scope :for_belt, -> { where(for_belt: true) }
  scope :classic, -> { where(for_belt: false) }

  def for_belt?
    for_belt == true
  end

  # `for_belt` est recopié : sans lui, cloner un exercice de ceinture en faisait un
  # exercice classique, qui changeait donc de liste.
  def new_clone
    Challenge.new(name: clone_name, content: cloned_content, skill_id:, for_belt:)
  end

  # « Copier en ceinture » : une copie de cet exercice dans les exercices de
  # ceinture de la même compétence, en fin de liste. L'original ne bouge pas.
  # Mêmes précautions qu'au clonage : ses tableaux sont dédoublés.
  def new_belt_copy
    Challenge.new(name: clone_name("Ceinture", liste: true), content: cloned_content, skill_id:, for_belt: true)
  end

  # Ranger l'exercice sous une autre compétence, en queue de sa liste.
  #
  # `update!(skill:)` seul ne suffit PAS. `acts_as_list` (0.7.7) ne sait pas
  # qu'on change de liste : l'exercice quitte l'ancienne en y laissant un TROU —
  # 1, 2, 4 — et emporte son ancienne position dans la nouvelle, où elle entre
  # en collision avec celle qui l'occupe déjà. L'ordre des deux compétences s'en
  # trouve faussé, en silence.
  #
  # D'où la séquence : sortir de la liste (ce qui la referme), changer de
  # compétence, puis entrer en queue de la nouvelle. `add_to_list_bottom` étant
  # privée dans cette version, on calcule le rang nous-mêmes.
  #
  # `for_belt` ne change pas : les listes sont scopées dessus, un exercice de
  # ceinture reste un exercice de ceinture, un exercice de compétence reste un
  # exercice de compétence. Les deux listes ne se mélangent jamais.
  #
  # L'auteur devient celui qui déplace : c'est lui qui décide désormais de la
  # place de cet exercice dans la progression — comme au clonage, où la copie
  # revient à qui l'a demandée.
  def transfer_to_skill!(nouvelle_competence, auteur:)
    transaction do
      remove_from_list
      update!(skill: nouvelle_competence, user: auteur)
      insert_at(Challenge.where(skill: nouvelle_competence, for_belt:).maximum(:position).to_i + 1)
    end
    self
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
  # Le nom doit être unique dans sa liste : celui construit sur `count + 1`
  # retombe sur un nom déjà pris dès qu'un exercice a été supprimé, et
  # l'enregistrement échouait alors en silence.
  #
  # `for_belt` : le même bouton dans l'éditeur de fiche de ceinture ; l'exercice
  # vide rejoint alors la liste des exercices de ceinture.
  def self.create_empty(skill, current_user, for_belt: false)
    challenge = Challenge.new(skill:, name: empty_challenge_name(skill, for_belt:), user: current_user, for_belt:)
    challenge.content = "#{for_belt ? 'Exercice de ceinture' : 'Exercice'} à REDIGER............................"
    challenge.save!
    challenge
  end

  # Le nom est unique par compétence et par liste : rang et noms pris se
  # cherchent dans la sienne.
  def self.empty_challenge_name(skill, for_belt: false)
    liste = Challenge.where(skill_id: skill.id, for_belt:)
    rang = liste.count + 1
    base = "#{skill.name} #{'Ceinture ' if for_belt}#{rang}-NEW"
    taken = liste.pluck(:name).to_set

    return base unless taken.include?(base)

    suffix = 2
    suffix += 1 while taken.include?("#{base}-#{suffix}")
    "#{base}-#{suffix}"
  end

  private

  # Suffixe déterministe plutôt que `rand(1..100)` : le nom est unique par
  # compétence et par liste, et deux clonages successifs pouvaient tirer le même
  # nombre — l'enregistrement échouait alors sans que l'utilisateur comprenne
  # pourquoi. `liste` : celle où la copie arrive (`for_belt`).
  def clone_name(suffixe = "Clone", liste: for_belt)
    base = "#{name}-#{suffixe}"
    taken = Challenge.where(skill_id:, for_belt: liste)
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
