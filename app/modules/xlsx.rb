module Xlsx
  def self.skills_generate_xlsx_file(school, grade, domains, skills)
    package = Axlsx::Package.new # create a package => https://github.com/caxlsx
    workbook = package.workbook
    header = %w[Ceinture Symbole Compétences]
    # definition du style
    styles = workbook.styles
    header_style = styles.add_style bg_color: "0089ca", font_name: "Courier",
                                    fg_color: "ff", sz: 20, alignment: { horizontal: :center }
    row_style = styles.add_style alignment: { horizontal: :center }
    # End definition du style
    # create a tab for each domain
    grade.domains.sort_by(&:position).each do |domain|
      workbook.add_worksheet(name: domain.name) do |sheet|
        sheet.add_row header.flatten
        sheet.column_widths 20, 20, nil
        sheet.row_style 0, header_style
        skills.select { |skill| skill.domain == domain }.sort_by { |skill| [skill.level, skill.position] }.each do |skill|
          sheet.add_row [domain.special? ? "" : Belt::BELT_COLORS[skill.level - 1], skill.symbol, skill.name],
                        style: [row_style, row_style, nil]
        end
      end
    end
    package # Return Axlspackage
  end

  # Xlsx.parse_xlsx_file
  def self.parse_xlsx_file(xlsx_path)
    # raise
    case File.extname(xlsx_path)
    when ".xlsx"
      SimpleXlsxReader.open(xlsx_path).sheets # renvoit all sheets sous l'objet SimpleXlsxReader::Document
    else
      # spreadsheet_obj = Roo::Spreadsheet.open(xlsx_path, extension: File.extname(xlsx_path)[1..-1].intern).sheets
      # Axlsx::Package.new do |p|
      #   p.workbook.add_worksheet(name: "Feuille1") do |sheet|
      #     spreadsheet_obj.each do |row|
      #       sheet.add_row row
      #     end
      #   end
      #   p.serialize("tmp/conversion.xlsx")
      # end
      # SimpleXlsxReader.open("tmp/conversion.xlsx").sheets
      # TO DO other spreadsheet format

    end
  end
end
