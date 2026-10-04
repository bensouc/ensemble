# frozen_string_literal: true

module Manipule
  # Une réponse proposée. Les trois d'un problème sont mélangées à l'affichage :
  # leur ordre en base ne dit rien à l'élève.
  class Choice < ApplicationRecord
    belongs_to :problem, inverse_of: :choices

    validates :label, presence: true
  end
end
