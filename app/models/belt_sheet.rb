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

  MODES = %w[en_cours resultats].freeze

  # Une fiche prête à imprimer, de deux façons :
  #
  # - `en_cours` : les ceintures EN COURS de l'élève — celles que son enseignant
  #   a décidé de lui faire passer en posant la compétence « ceinture » dans un
  #   plan de travail, pas encore passée (`ceintures_en_cours`). Un domaine coché
  #   sans ceinture en cours arrive vide ;
  # - `resultats` : selon ses résultats — pour chaque domaine, la ceinture qui
  #   suit la dernière validée, avec ses compétences pas encore validées.
  #
  # Un bloc par domaine et ceinture. `domains` : ceux cochés dans la modale ;
  # sans choix, ceux qui ont une ceinture en cours (`en_cours`), ou tous les
  # domaines non spéciaux (`resultats`). Un domaine spécial — validé au score —
  # arrive vide dans le second mode. L'enseignant ajuste ensuite dans l'éditeur.
  def self.prepare!(student, user, domains: nil, mode: "resultats")
    mode == "en_cours" ? preparer_en_cours!(student, user, domains) : preparer_selon_resultats!(student, user, domains)
  end

  def self.preparer_en_cours!(student, user, domains)
    en_cours = ceintures_en_cours(student).group_by(&:domain)
    remplir!(student, user, domains || en_cours.keys) do |sheet, domain|
      sheet.ajouter_en_cours!(domain, en_cours.fetch(domain, []))
    end
  end

  def self.preparer_selon_resultats!(student, user, domains)
    remplir!(student, user, domains || student.grade.domains.reject(&:special?)) do |sheet, domain|
      sheet.ajouter_selon_resultats!(domain)
    end
  end

  # La fiche, puis un passage par domaine, dans l'ordre de l'école.
  def self.remplir!(student, user, domains)
    transaction do
      create!(student:, user:).tap do |sheet|
        domains.sort_by(&:position).each { |domain| yield sheet, domain }
      end
    end
  end

  # Les compétences sur lesquelles l'élève passe sa ceinture : son dernier WPS y
  # est posé « ceinture » (ou « contrôle », son équivalent) et n'a pas encore été
  # évalué — ni validé, ni raté (une ceinture ratée repasse en exercice).
  def self.ceintures_en_cours(student)
    skills = Skill.where(domain_id: student.grade.domains.select(:id))
    WorkPlanSkill.last_wps(student, skills).includes(skill: :domain).select { |wps| en_cours?(wps) }.
      map(&:skill).sort_by { |skill| [skill.level, skill.position.to_i, skill.id] }
  end

  def self.en_cours?(wps)
    %w[ceinture controle].include?(wps.kind) && wps.status == "new"
  end

  # La ceinture qui suit la dernière validée, avec ses compétences pas encore
  # validées ; un domaine spécial, qui n'en a qu'une, arrive vide.
  def ajouter_selon_resultats!(domain)
    level = domain.special? ? 1 : prochaine_ceinture(domain)
    add_domain!(domain, level) if level
  end

  # Les blocs d'un domaine, une ceinture par bloc. Sans ceinture en cours, un
  # bloc vide, à la ceinture que l'élève prépare — la blanche pour un domaine
  # spécial, qui n'en a qu'une.
  def ajouter_en_cours!(domain, skills)
    if skills.empty?
      level = domain.special? ? 1 : prochaine_ceinture(domain)
      belt_sheet_domains.create!(domain:, level:) if level
      return
    end

    skills.group_by(&:level).each do |level, competences|
      bloc = belt_sheet_domains.create!(domain:, level:)
      competences.each { |skill| bloc.add_skill!(skill) }
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
