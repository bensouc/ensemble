module PdfGenerator
  class StudentResultPdf < PdfGenerator::Base
    attr_reader :title

    def initialize(student, layout = "pdf")
      super(layout)
      @student = student
      @domains = @student.domains.sort_by(&:position)
      @skills = @student.grade.skills
      @results = Result.completed_for_student(@student)
      @title = "Progression de #{@student.first_name}- #{Time.now.strftime("%d/%m/%Y")}"
    end

    def generate
      # Utilisation de WickedPdf pour générer le PDF à partir d'une vue HTML
      pdf_html = ActionController::Base.new.render_to_string("pdfs/student_results", layout: @layout)

      # Conversion du HTML en PDF
      WickedPdf.new.pdf_from_string(pdf_html)
    end
  end
end
