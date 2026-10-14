# frozen_string_literal: true

class BeltSheet
  # Une fiche de ceinture d'aucun élève : le professeur la génère depuis les
  # exercices de ceinture, pour un niveau, et l'imprime telle quelle. Sans
  # élève, rien n'est validé, aucun exercice n'a été donné, et la ceinture d'un
  # bloc se choisit au lieu de se déduire.
  module NonAssignee
    extend ActiveSupport::Concern

    included do
      # Le niveau d'une fiche non assignée ; celle d'un élève tient le sien de
      # sa classe (`grade`).
      belongs_to :grade, optional: true
      validates :grade, presence: true

      scope :non_assignees, -> { where(student_id: nil) }
    end

    class_methods do
      # Depuis les exercices de ceinture : le domaine et la ceinture des filtres,
      # toutes ses compétences, et pour chacune le premier exercice de ceinture
      # de sa liste. Un domaine spécial arrive vide, à sa seule ceinture, la
      # blanche : c'est au professeur de construire sa fiche.
      def generer!(grade, domain, level, user)
        transaction do
          create!(grade:, user:).tap { |sheet| sheet.add_domain!(domain, domain.special? ? 1 : level) }
        end
      end
    end

    def non_assignee?
      student_id.nil?
    end

    # Le niveau de l'élève, ou celui que porte une fiche non assignée.
    def grade
      student ? student.grade : super
    end

    # Le nom d'une fiche non assignée dans la liste : ses blocs, domaine et
    # ceinture, dans l'ordre de l'école.
    def nom_des_blocs
      dans_l_ordre(belt_sheet_domains).map { |bloc| "#{bloc.domain.name} #{bloc.couleur}" }.join(" · ").presence ||
        "Fiche vide"
    end
  end
end
