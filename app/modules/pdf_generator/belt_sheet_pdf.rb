# frozen_string_literal: true

module PdfGenerator
  # La fiche de ceinture d'un élève, imprimée à part du plan de travail pour être
  # collée dans le cahier : un bloc par domaine et ceinture, le plus de blocs
  # possible par page, et jamais un bloc coupé en deux.
  class BeltSheetPdf < PdfGenerator::Base
    attr_reader :title

    def initialize(belt_sheet, layout = "pdf")
      super(layout)
      @belt_sheet = belt_sheet
      @title = belt_sheet.title
    end

    def generate
      html = render_html("pdfs/belt_sheet", { belt_sheet: @belt_sheet, blocs: @belt_sheet.ordered_domains })
      html_to_pdf(html, { display_header_footer: true, margin_bottom: 0.6, footer_template: })
    end

    private

    def footer_template
      eleve = ERB::Util.html_escape(@belt_sheet.student.first_name.to_s.capitalize)
      date = I18n.l(@belt_sheet.created_at.to_date)
      pages = "Page <span class='pageNumber'></span>/<span class='totalPages'></span>"
      "<div style='font-size: 8px; width: 100%; text-align: right; padding-right: 20px;'>" \
        "#{eleve} - Fiche de ceinture du #{date} - #{pages}</div>"
    end
  end
end
