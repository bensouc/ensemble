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

      # Conversion du HTML en PDF avec Ferrum
      html_to_pdf(pdf_html)
    end
  end
end
