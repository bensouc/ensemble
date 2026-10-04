# frozen_string_literal: true

class StudentsController < ApplicationController
  before_action :set_student, only: %i[show]

  def show
    authorize @student
    respond_to do |format|
      format.html do
        @belt = Belt::BELT_COLORS
        @domains = @student.domains.sort_by(&:position)
      end
      format.pdf do
        data_pdf = PdfGenerator::StudentResultPdf.new(@student)
        send_data data_pdf.generate,
                  filename: "#{data_pdf.title}.pdf",
                  type: "application/pdf",
                  disposition: "attachment" # sending the pdf to the browser as a file
      end
    end
  end

  def new
    @classroom = Classroom.find(classroom_params_id)
    @student = Student.new(classroom: @classroom)
    authorize @student, :create?
  end

  def create
    classroom = Classroom.find(params_student[:classroom])
    @student = Student.new(first_name: params_student[:first_name], classroom:)
    authorize @student
    @student.save!
    redirect_to classrooms_path
  end

  def update
    @student = Student.find(params[:id])
    authorize @student
    @student.first_name = params_student_edit_name[:first_name]
    @student.save
    redirect_to classrooms_path
  end

  def destroy
    @student = Student.find(params[:id])
    authorize @student
    @student.destroy
    # 303 : le lien envoie un vrai DELETE (Turbo), qu'un 302 ferait rejouer
    # sur la page de destination.
    redirect_to classrooms_path, status: :see_other
  end

  def new_validated_wps
    # create the view for add validated skills on student
    @student = Student.includes(:classroom).find(params_add_validated_wps[:student_id])
    authorize @student, :update?
    student_grade = @student.grade
    @special_work_plan = WorkPlan.find_or_create_by(student: @student, grade: student_grade, special_wps: true)
    domain = Domain.find(params_add_validated_wps[:domain])
    level = if domain.special?
              1
            else
              params_add_validated_wps[:level].to_i
            end
    skills = domain.skills.select { |skill| skill.level == level }
    @no_validated_skills = skills.reject do |skill|
      Result.find_by(skill:, student: @student, kind: "ceinture", status: "completed")
    end
    # La liste des sous-domaines a disparu d'ici. Le contrôleur posait
    # `@subdomain`, la vue lisait `@sub_domains` : le groupement ne s'est donc
    # jamais exécuté. Plutôt que d'accorder les deux noms, la vue groupe
    # elle-même, par `competences_par_sous_domaine` — il n'y a plus deux endroits
    # à tenir d'accord.
    # binding.pry
    return if @no_validated_skills.nil? || @no_validated_skills.empty?

    # redirect_to student_path(@student), flash: { notice: "Il n'y pas de compétence à ajouter pour ce domaine/niveau" }
    @special_work_plan.user = current_user
    @special_work_plan.name = "special_work_plan"
    @special_work_plan.save!
  end

  private

  def set_student
    @student = Student.find(params[:id])
  end

  def params_add_validated_wps
    params.permit(:student_id, :level, :domain)
  end

  def params_student
    params.require(:student)
  end

  def params_student_edit_name
    params.expect(student: [:first_name])
  end

  def classroom_params_id
    params.require(:classroom_id)
  end

  # controller method to clean OOPed
  # def wps_cleaned_belt(all_skills_last_wpss, domain, count, grade)
  #   # "Géométrie", "Grandeurs et Mesures"
  #   belt_validation = Belt.score_to_validate(grade)
  #   to_remove = belt_validation.find { |d| d[:domain] == domain }[:validation][count - 1]
  #   (1..to_remove).to_a.each do
  #     # get index for wps completed
  #     index = all_skills_last_wpss.index do |h|
  #       # binding.pry
  #       h[:skill][:domain] == domain && !h[:last_wps].nil? && h[:last_wps].status == "completed"
  #       # h[:skill][:domain] == domain && h[:skill][:grade] == grade && !h[:last_wps].nil? && h[:last_wps].status == "completed"
  #     end
  #     # delete @ index if index exists
  #     all_skills_last_wpss.delete_at(index) unless index.nil?
  #     # all_skills_last_wpss.select { |h| h[:skill][:domain] == domain && !h[:last_wps].nil? }.count
  #   end
  #   all_skills_last_wpss
  # end

  def get_last_completed_or_created_wps(all_last_wps, skill)
    last_wps = all_last_wps.select { |wps| wps.skill == skill && wps.completed }.max_by(&:created_at)
    # find if one is completed then select it
    last_wps = all_last_wps.select { |wps| wps.skill == skill }.max_by(&:created_at) if last_wps.nil?
    last_wps
  end
end
