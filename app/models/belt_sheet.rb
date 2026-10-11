# frozen_string_literal: true

# La fiche de ceinture d'un élève : des blocs — un domaine à une couleur de
# ceinture —, chacun portant ses compétences et l'exercice de ceinture donné
# pour chacune. Elle s'imprime à part du plan de travail, pour être collée dans
# le cahier.
#
# Elle n'évalue rien : elle LIT les résultats de l'élève pour se préparer, et
# n'en écrit jamais. La réussite d'une ceinture se saisit dans le plan de
# travail.
class BeltSheet < ApplicationRecord
  belongs_to :student
  # Une fiche survit au départ de son auteur, comme un exercice.
  belongs_to :user, optional: true
  has_many :belt_sheet_domains, dependent: :destroy
  has_many :belt_sheet_skills, through: :belt_sheet_domains

  delegate :grade, to: :student

  # Une fiche prête à imprimer : pour chaque domaine du niveau de l'élève, la
  # ceinture qui suit la dernière qu'il a validée, avec les compétences de cette
  # ceinture qu'il n'a pas encore validées.
  #
  # Les domaines spéciaux, validés au score et non compétence par compétence,
  # ne sont pas préparés : l'enseignant les ajoute à la main.
  def self.prepare!(student, user)
    transaction do
      sheet = create!(student:, user:)
      student.grade.domains.reject(&:special?).sort_by(&:position).each do |domain|
        level = sheet.prochaine_ceinture(domain)
        sheet.add_domain!(domain, level) if level
      end
      sheet
    end
  end

  # La ceinture qui suit la dernière validée dans ce domaine ; `nil` quand
  # l'élève a déjà la noire.
  def prochaine_ceinture(domain)
    level = Belt.completed.where(student:, domain:).maximum(:level).to_i + 1
    level if level <= Belt::BELT_COLORS.size
  end

  # Ajoute le bloc domaine / ceinture et le garnit des compétences que l'élève
  # n'a pas encore validées. Un bloc où il a tout validé ne s'ajoute pas : il
  # n'y aurait rien à lui faire passer.
  #
  # Renvoie le bloc, ou `nil` s'il n'a pas été ajouté.
  def add_domain!(domain, level)
    skills = Skill.where(domain:, level:).ordered.reject { |skill| competence_validee?(skill) }
    return nil if skills.empty?

    bloc = belt_sheet_domains.create!(domain:, level:)
    skills.each { |skill| bloc.add_skill!(skill) }
    bloc
  end

  # Validée en ceinture : par son résultat, ou parce que la ceinture entière l'a
  # été — la règle de `Student#skill_completed`.
  def competence_validee?(skill)
    competences_validees.include?(skill.id) || ceintures_validees.include?([skill.domain_id, skill.level])
  end

  # Les blocs dans l'ordre des domaines tel que l'école l'a défini, puis des
  # ceintures — jamais dans l'ordre où on les a ajoutés.
  def ordered_domains
    belt_sheet_domains.includes(:domain).sort_by { |bloc| [bloc.domain.position.to_i, bloc.level, bloc.id] }
  end

  def title
    "Ceintures - #{student.first_name} - #{I18n.l(created_at.to_date)}"
  end

  private

  def competences_validees
    @competences_validees ||= Result.completed.where(student:).pluck(:skill_id).to_set
  end

  def ceintures_validees
    @ceintures_validees ||= Belt.completed.where(student:).pluck(:domain_id, :level).to_set
  end
end
