# frozen_string_literal: true

class SharedClassroom < ApplicationRecord
  belongs_to :user
  belongs_to :classroom

  validates :user,
            uniqueness: { message: "Cette classe a déjà été partagée avec un des professeurs sélectionnés",
                          scope: :classroom }
end
