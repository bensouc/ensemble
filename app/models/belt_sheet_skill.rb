# frozen_string_literal: true

# Une compétence d'un bloc de la fiche de ceinture, et l'exercice de ceinture
# donné pour elle. Pas de type, contrairement au plan de travail : toute ligne
# d'une fiche est une ceinture.
class BeltSheetSkill < ApplicationRecord
  belongs_to :belt_sheet_domain
  acts_as_list scope: :belt_sheet_domain
  include Positionable

  belongs_to :skill
  belongs_to :challenge, optional: true

  has_one :belt_sheet, through: :belt_sheet_domain

  delegate :student, to: :belt_sheet_domain

  validates :skill_id, uniqueness: { scope: :belt_sheet_domain_id }

  # Le premier exercice de ceinture de la compétence que l'élève n'a pas encore
  # eu sur une fiche, dans l'ordre choisi par l'enseignant. Aucun quand la liste
  # est épuisée : l'éditeur propose alors d'en charger un ou d'en créer un.
  def next_challenge
    Challenge.for_belt.where(skill_id:).where.not(id: challenges_deja_donnes).ordered.first
  end

  def attach_challenge!
    update!(challenge: next_challenge)
  end

  def deja_validee?
    belt_sheet_domain.belt_sheet.competence_validee?(skill)
  end

  private

  # Les exercices de ceinture de cette compétence déjà donnés à l'élève, sur
  # cette fiche ou une autre.
  def challenges_deja_donnes
    BeltSheetSkill.joins(belt_sheet_domain: :belt_sheet).
      where(skill_id:, belt_sheets: { student_id: student.id }).
      where.not(id:).where.not(challenge_id: nil).select(:challenge_id)
  end
end
