# frozen_string_literal: true

# Le transfert d'un élève vers une autre classe, exposé comme une ressource :
# `new` sert le formulaire, `create` réalise le déplacement.
class StudentTransfersController < ApplicationController
  before_action :set_student

  # Chargé à la demande dans le turbo-frame "general_modal" : la page d'index des
  # classes ne rend donc aucun formulaire de transfert tant qu'on n'a pas cliqué.
  def new
    authorize @student, :transfer?
    # Préchargé ici, et pas dans le modèle : seul l'affichage des libellés en a besoin.
    @target_classrooms = @student.transferable_classrooms.includes(:user, :grade, shared_classrooms: :user)
  end

  # On ne cherche la classe cible QUE parmi transferable_classrooms : un id forgé
  # à la main ne peut donc ni sortir l'élève de son niveau, ni de son école.
  def create
    authorize @student, :transfer?
    target = @student.transferable_classrooms.find_by(id: transfer_params[:classroom_id])

    if target.nil?
      redirect_to classrooms_path,
                  alert: "Transfert impossible : cette classe n'est pas disponible pour #{@student.first_name}."
    else
      # Formulation sans accord de genre : Student n'a pas de champ pour le sexe.
      notice = "#{@student.first_name} a changé de classe : #{@student.classroom.safe_name} → #{target.safe_name}."
      @student.update!(classroom: target)
      redirect_to classrooms_path, notice:
    end
  end

  private

  def set_student
    @student = Student.find(params[:student_id])
  end

  def transfer_params
    params.require(:student).permit(:classroom_id)
  end
end
