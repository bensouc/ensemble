# frozen_string_literal: true

class Challenge < ApplicationRecord
  belongs_to :skill
  belongs_to :user
  has_rich_text :content
  has_many_attached :photos, dependent: :destroy
  has_one :school, through: :skill

  has_many :work_plan_skills, dependent: nil

  validates :name, presence: true, uniqueness: { message: "Le nom de cet exercice éxiste déja", scope: :skill }
  validates :shared, presence: true

  scope :for_belt, -> { where(for_belt: true) }
  scope :classic, -> { where(for_belt: false) }

  def for_belt?
    for_belt == true
  end

  def new_clone
    Challenge.new(name: "#{name}-Clone#{rand(1..100)}", content: cloned_content, skill_id:)
  end


  # CLASS METHOD

  def self.assigned_challenges(skill, student)
    wpss = WorkPlanSkill.where(skill_id: skill.id, kind: "exercice").select { |wps| wps.student == student }
    # challenge = []
    wpss.map(&:challenge)
  end

  def self.create_empty(work_plan_skill, name, current_user)
    challenge = Challenge.create({
                                   skill: work_plan_skill.skill,
                                   name: "#{name}-NEW",
                                   user: current_user
                                 })
    challenge.content.body = <<~HTML
      Exercice à REDIGER............................
    HTML
    challenge.save
    challenge
  end

  private

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
