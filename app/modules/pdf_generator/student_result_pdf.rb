module PdfGenerator
  class StudentResultPdf < PdfGenerator::Base
    attr_reader :title

    def initialize(student, layout = "pdf")
      super(layout)
      @student = student
      @domains = @student.domains.includes(:skills).sort_by(&:position)
      @skills = @student.grade.skills.includes(:domain)
      @results = Result.includes([:skill]).completed_for_student(@student)
      @title = "Progression de #{@student.first_name}- #{Time.now.strftime("%d/%m/%Y")}"
    end

    def generate
      # Utilisation de WickedPdf pour générer le PDF à partir d'une vue HTML
      pdf_html = ActionController::Base.new.render_to_string("pdfs/student_results",
        layout: @layout,
        locals: { student: @student, skills: @skills, results: @results, domains: @domains, title: @title }
        )

      # Conversion du HTML en PDF
      WickedPdf.new.pdf_from_string(pdf_html,
        # Options de configuration de WickedPdf
      header: {
          right: "Progression de #{@student.first_name}",
          show_on_first_page: false # Titre du document
      },
      footer: {
          # center: , # Affiche le numéro de page courant et le nombre total de pages
          right: "Progression de #{@student.first_name} [page] / [topage]",
          font_size: 8,
          spacing: 5
        })
    end
  end
end
