module PdfGenerator
  class StudentResultPdf < PdfGenerator::Base
    attr_reader :title

    def initialize(student, layout = "pdf")
      super(layout)
      @student = student
      @domains = Domain.where(grade: @student.grade).sort_by(&:position)
      @skills = @student.grade.skills.includes(:domain)
      @validated_skills = @student.all_belt_results
      # @belts = @student.belts.includes([:domain]).completed
      # @results = Result.completed_for_student(@student)
      @title = "Progression de #{@student.first_name}- #{Time.now.strftime("%d/%m/%Y")}"
    end

    def generate
      # Génération du HTML à partir de la vue
      pdf_html = ActionController::Base.new.render_to_string("pdfs/student_results",
        layout: @layout,
        locals: { student: @student, skills: @skills, results: @validated_skills,
                  domains: @domains, title: @title }
      )

      # Conversion du HTML en PDF avec Ferrum
      html_to_pdf(pdf_html, {
        display_header_footer: true,
        margin_bottom: 0.6,
        footer_template: "<div style='font-size: 8px; width: 100%; text-align: right; padding-right: 20px;'>Progression de #{@student.first_name.capitalize} - #{Time.now.strftime('%d/%m/%Y')} - Page <span class='pageNumber'></span>/<span class='totalPages'></span></div>"
      })
    end
  end
end
