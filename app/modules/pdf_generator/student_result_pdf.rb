module PdfGenerator
  class StudentResultPdf < PdfGenerator::Base
    attr_reader :title

    def initialize(student, layout = "pdf")
      super(layout)
      @student = student
      @domains = Domain.where(grade: @student.grade).sort_by(&:position)
      @skills = @student.grade.skills.includes(:domain)
      @validated_skills = @student.all_completed_skills
      # @belts = @student.belts.includes([:domain]).completed
      # @results = Result.completed_for_student(@student)
      @title = "Progression de #{@student.first_name}- #{Time.now.strftime("%d/%m/%Y")}"
    end

    def generate
      # Génération du HTML à partir de la vue
      pdf_html = ActionController::Base.new.render_to_string("pdfs/student_results",
        layout: @layout,
        locals: { student: @student, skills: @skills, results: @validated_skills,
                  domains: @domains, title: @title, belts: @belts }
        )

      # Conversion du HTML en PDF avec Ferrum
      footer_text = "Progression de #{@student.first_name.capitalize} en date du #{Time.now.strftime("%d/%m/%Y")}"

      html_to_pdf(pdf_html,
        display_header_footer: true,
        footer_template: "<div style='font-size: 8px; text-align: right; width: 100%; padding-right: 20px;'>#{footer_text} Page: <span class='pageNumber'></span> / <span class='totalPages'></span></div>",
        margin_bottom: 0.6
      )
    end
  end
end
