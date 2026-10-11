# frozen_string_literal: true

# Un bloc de la fiche de ceinture : un domaine à une couleur de ceinture. C'est
# l'unité de la mise en page — un bloc ne se coupe jamais à l'impression.
class BeltSheetDomain < ApplicationRecord
  belongs_to :belt_sheet
  belongs_to :domain
  has_many :belt_sheet_skills, -> { ordered }, dependent: :destroy, inverse_of: :belt_sheet_domain

  delegate :student, to: :belt_sheet

  validates :level, inclusion: { in: 1..Belt::BELT_COLORS.size }
  validates :domain_id, uniqueness: { scope: [:belt_sheet_id, :level] }

  def couleur
    Belt::BELT_COLORS[level - 1]
  end

  def add_skill!(skill)
    belt_sheet_skills.create!(skill:).tap(&:attach_challenge!)
  end
end
