# frozen_string_literal: true

module Mobile
  # Sur la fiche mobile d'un élève, un appui sur la ceinture d'un domaine ouvre
  # les compétences de la ceinture suivante ; chaque appui sur une compétence
  # l'enregistre aussitôt (voir `CeintureSuivante`).
  class ValidationsController < ApplicationController
    # La modale s'ouvre dans le cadre `general_modal`. Le layout mobile porte
    # déjà un cadre de ce nom, vide : rendue avec lui, la réponse en contenait
    # deux, et Turbo prenait le premier — rien ne s'ouvrait.
    layout -> { turbo_frame_request? ? "turbo_rails/frame" : "mobile" }
    before_action :set_student_and_domain

    def edit
      @ceinture = CeintureSuivante.new(@student, @domain)
    end

    def update
      @ceinture = CeintureSuivante.new(@student, @domain, level: validation_params[:level])
      @obtenue = @ceinture.enregistrer!(validation_params[:skill_id], validee: validee?)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to mobile_classroom_student_path(@student.classroom, @student) }
      end
    end

    private

    # Valider une compétence, c'est évaluer l'élève : la règle de
    # `StudentsController#new_validated_wps`. Le domaine se cherche dans ceux de
    # son niveau — celui d'un autre niveau, ou d'une autre école, est un 404.
    def set_student_and_domain
      @student = Student.includes(:classroom).find(params[:student_id])
      authorize @student, :update?
      @domain = @student.grade.domains.find(params[:domain_id])
    end

    def validation_params
      params.expect(validation: [:skill_id, :validee, :level])
    end

    def validee?
      ActiveModel::Type::Boolean.new.cast(validation_params[:validee])
    end
  end
end
