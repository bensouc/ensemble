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
      # Utilisation de WickedPdf pour générer le PDF à partir d'une vue HTML
      pdf_html = ActionController::Base.new.render_to_string("pdfs/work_plan",
                                                             layout: @layout,
                                                             locals: { work_plan: @work_plan, belt: @belt, work_plan_domains: @work_plan_domains,
                                                                       domains: @domains, title: @title })

      # Conversion du HTML en PDF
      WickedPdf.new.pdf_from_string(pdf_html,
      # Options de configuration de WickedPdf
      # header: {
      #     right: "Progression de #{@student.first_name}",
      #     show_on_first_page: false # Titre du document
      # },
      footer: {
      # center: , # Affiche le numéro de page courant et le nombre total de pages
        right: "#{@title}- Du #{@work_plan.start_date.strftime("%d/%m/%Y")} Au #{@work_plan.end_date.strftime("%d/%m/%Y")}     Page: [page] / [topage]",
        font_size: 8,
        spacing: 5
      })
    end
  end
end
