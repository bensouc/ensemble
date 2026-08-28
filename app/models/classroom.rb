# frozen_string_literal: true

class Classroom < ApplicationRecord
  GRADE = %w[CP CE1 CE2 CM1 CM2].freeze
  belongs_to :user
  belongs_to :grade # to remove for first migration Of Grade MODEL

  has_many :students, dependent: :destroy
  # `dependent: nil` face à une clé étrangère en RESTRICT : détruire une classe
  # partagée levait `InvalidForeignKey`, y compris en cascade depuis le prof, le
  # niveau ou l'école. Une suppression en gros doit bien emporter les partages ;
  # la suppression délibérée d'UNE classe, elle, passe par
  # `destroy_or_hand_over!`, qui applique la règle du transfert.
  has_many :shared_classrooms, dependent: :destroy

  validates :grade, presence: true
  before_validation :set_default

  def shared?
    shared_classrooms.any?
  end

  # Supprimer une classe partagée ne la détruit pas : sa propriété passe à l'un
  # des profs du partage, qui devient le teacher — son lien de partage n'a donc
  # plus de raison d'être. Les autres partages subsistent. Une classe qui n'est
  # partagée avec personne est détruite, elle et tout ce qui en dépend.
  #
  # Le tout dans une transaction : le `save` sans `!` d'avant laissait le partage
  # être détruit alors que le transfert avait échoué, et le collègue perdait
  # l'accès à une classe restée chez son propriétaire.
  #
  # `order(:id)` parce que `first` sans ORDER BY ne désigne pas un repreneur
  # stable : on prend le partage le plus ancien, donc le premier collègue.
  def destroy_or_hand_over!
    transaction do
      share = shared_classrooms.order(:id).first
      if share.nil?
        destroy!
      else
        update!(user: share.user)
        share.destroy!
      end
    end
    self
  end

  def results_pdf_exists?
    zipfile_name = "classroom_#{id}_students_pdfs.zip"
    zipfile_path = Rails.root.join("tmp", zipfile_name)
    return false, nil unless File.exist?(zipfile_path)

    creation_time = File.ctime(zipfile_path)
    [true, creation_time]
  end

  # Le premier professeur avec qui la classe est partagée, nil si elle ne l'est
  # pas. `order(:id)` pour que « premier » veuille dire quelque chose : sans lui,
  # Postgres ne garantit aucun ordre.
  def shared_user
    shared_classrooms.order(:id).first&.user
  end

  def safe_name
    name == "" ? grade.grade_level : name
  end

  def teachers
    [user, *shared_classrooms.map(&:user)].uniq
  end

  # Les autres classes du même niveau. Un grade appartenant à une école, elles
  # sont de fait dans la même école que celle-ci.
  def sibling_classrooms
    grade.classrooms.where.not(id: id)
  end

  def completed_results_by_domain(domain)
    # {student_id: Result.where(skills: domain.skills, student: student)}
    results = {}
    temp_results = Result.includes([:student, :skill]).where(skill: domain.skills, students: students)
    students.each do |student|
      results[student] = temp_results.select do |result|
        result.student == student && result.status == "completed" && result.kind == "ceinture"
      end
    end
    results
  end

  private

  def set_default
    self.name = "" if name.nil? || name == ""
  end
end
