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

    # Pas de bas de page, et des marges hautes et basses réduites : la place va
    # aux blocs. Le prénom et la date sont déjà dans chaque cartouche.
    MARGES = { margin_top: 0.2, margin_bottom: 0.2 }.freeze # pouces

    def generate
      html = render_html("pdfs/belt_sheet", { belt_sheet: @belt_sheet, blocs: @belt_sheet.ordered_domains })
      html_to_pdf(html, MARGES)
    end
  end
end
