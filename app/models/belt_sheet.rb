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

  # Une fiche prête à imprimer : pour chaque domaine choisi, la ceinture qui suit
  # la dernière que l'élève a validée, avec les compétences de cette ceinture
  # qu'il n'a pas encore validées.
  #
  # Sans choix, tous les domaines de son niveau sauf les spéciaux. Un domaine
  # spécial — validé au score, non compétence par compétence — n'est préparé que
  # s'il est choisi, et arrive alors vide (`add_domain!`).
  def self.prepare!(student, user, domains: nil)
    domains ||= student.grade.domains.reject(&:special?)
    transaction do
      sheet = create!(student:, user:)
      domains.sort_by(&:position).each do |domain|
        level = domain.special? ? 1 : sheet.prochaine_ceinture(domain)
        sheet.add_domain!(domain, level) if level
      end
      sheet
    end
  end

  # Les élèves vers qui cloner cette fiche : ceux du même niveau, dans les
  # classes de l'enseignant — les siennes et celles qu'on lui partage — qui ont
  # ouvert les fiches de ceinture. Pas l'élève de la fiche.
  def clone_candidates(user)
    partagees = SharedClassroom.where(user:).select(:classroom_id)
    classes = Classroom.where(belt_sheets: true, grade_id: student.classroom.grade_id).
      where(user:).or(Classroom.where(belt_sheets: true, grade_id: student.classroom.grade_id, id: partagees))
    Student.where(classroom: classes).where.not(id: student_id).includes(:classroom).order(:first_name)
  end

  # Une copie de la fiche pour un autre élève du même niveau : les mêmes blocs,
  # les mêmes compétences, les mêmes exercices. Les compétences qu'il a déjà
  # validées y restent — l'éditeur les marque « Déjà validée », l'enseignant
  # décide.
  def clone_for!(student, user)
    transaction do
      copie = BeltSheet.create!(student:, user:)
      ordered_domains.each do |bloc|
        nouveau = copie.belt_sheet_domains.create!(domain: bloc.domain, level: bloc.level)
        bloc.belt_sheet_skills.each do |ligne|
          nouveau.belt_sheet_skills.create!(skill: ligne.skill, challenge: ligne.challenge)
        end
      end
      copie
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
  # Un domaine spécial arrive VIDE : il n'a qu'une ceinture, qui porte toutes ses
  # compétences — une vingtaine en géométrie —, et se valide au score. C'est à
  # l'enseignant de choisir celles qu'il fait passer.
  #
  # Renvoie le bloc, ou `nil` s'il n'a pas été ajouté.
  def add_domain!(domain, level)
    return belt_sheet_domains.create!(domain:, level:) if domain.special?

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
    belt_sheet_domains.includes(:domain, belt_sheet_skills: [:skill, { challenge: :rich_text_content }]).
      sort_by { |bloc| [bloc.domain.position.to_i, bloc.level, bloc.id] }
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
