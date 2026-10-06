class Grade < ApplicationRecord
  # `optional` : la colonne accepte NULL en base. À resserrer (NOT NULL, puis
  # `optional` retiré) une fois les lignes vides comptées en production.
  belongs_to :school, optional: true
  has_many :classrooms, dependent: :destroy
  has_many :work_plans, dependent: :destroy
  # `domains` ne rend QUE les domaines d'Ensemble. La progression d'un élève,
  # la grille de ceintures et la génération des plans passent toutes par là —
  # les filtrer au cas par cas aurait voulu dire les filtrer dans dix-huit
  # endroits, et en oublier un ne se serait vu qu'une fois « Autre » apparu
  # dans un plan de travail.
  #
  # Les deux portent `dependent: :destroy`, et elles se complètent : `manipule`
  # est NOT NULL, donc `false` et `true` couvrent toute la table. Sans cela,
  # supprimer un niveau aurait laissé ses domaines Manipule derrière lui — la
  # clef étrangère `domains → grades` n'a pas d'`on_delete`, et la base aurait
  # refusé.
  has_many :domains, -> { where(manipule: false) }, dependent: :destroy, inverse_of: :grade
  has_many :domaines_manipule, -> { where(manipule: true) }, class_name: "Domain",
                                                             dependent: :destroy, inverse_of: :grade
  has_many :students, through: :classrooms, source: "students", dependent: :destroy
  # Donc `grade.skills` ignore lui aussi les compétences de Manipule.
  has_many :skills, through: :domains

  validates :grade_level, presence: true, inclusion: Classroom::GRADE
  validates :name,  presence: true,
                    uniqueness: { message: "est déjà utilisé dans votre école", scope: :school },
                    length: { maximum: 15, message: "est trop long (pas plus de 15 caractères)" }

  before_validation :set_default

  def self.find_grade_by_school_and_grade_level(school, grade_level)
    Grade.find_by(grade_level:, school:)
  end

  private

  def set_default
    self.name = grade_level if name.nil? || name == ""
  end
end
