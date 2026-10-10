# frozen_string_literal: true

# Un domaine qu'un professeur a sorti de la génération automatique de ses plans
# de travail. Le domaine reste proposé dans la modale, simplement décoché : le
# reprendre pour un élève reste un clic.
class AutoGenExclusion < ApplicationRecord
  belongs_to :user
  belongs_to :domain

  validates :domain_id, uniqueness: { scope: :user_id }

  # Parmi `domains`, ceux que la génération automatique coche d'office : tous,
  # sauf ceux que `user` en a sortis depuis la page des domaines.
  def self.auto_domains(domains, user:)
    excluded = where(user:).pluck(:domain_id)
    domains.reject { |domain| excluded.include?(domain.id) }
  end
end
