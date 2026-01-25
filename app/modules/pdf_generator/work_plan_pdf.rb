module PdfGenerator
  class WorkPlanPdf < PdfGenerator::Base
    attr_reader :title

    def initialize(work_plan, belt, work_plan_domains, domains, layout = "pdf")
      super(layout)
      @work_plan = work_plan
      @belt = belt
      @work_plan_domains = work_plan_domains
      @domains = domains
      @title = "#{work_plan.name}  #{work_plan.student&.first_name}"
    end

    def generate
      # Génération du HTML à partir de la vue
      pdf_html = ActionController::Base.new.render_to_string("pdfs/work_plan",
                                                             layout: @layout,
                                                             locals: { work_plan: @work_plan, belt: @belt, work_plan_domains: @work_plan_domains,
                                                                       domains: @domains, title: @title })

      # Écrire le HTML dans un fichier pour debug
      if Rails.env.development?
        File.write(Rails.public_path.join("work_plan_preview.html"), pdf_html)
        Rails.logger.info "PDF HTML écrit dans public/work_plan_preview.html"
      end

      # Conversion du HTML en PDF avec Ferrum
      student_name = @work_plan.student&.first_name&.capitalize || ""
      footer_text = "#{student_name} - #{@work_plan.name} - Du #{@work_plan.start_date.strftime('%d/%m/%Y')} au #{@work_plan.end_date.strftime('%d/%m/%Y')} - Page <span class='pageNumber'></span>/<span class='totalPages'></span>"
      html_to_pdf(pdf_html, {
                    display_header_footer: true,
                    margin_bottom: 0.6,
                    footer_template: "<div style='font-size: 8px; width: 100%; text-align: right; padding-right: 20px;'>#{footer_text}</div>"
                  })
    end
  end
end
