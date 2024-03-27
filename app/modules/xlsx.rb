module Xlsx


  def self.skills_generate_xlsx_file(school, grade, domains, skills)

    package = Axlsx::Package.new
    workbook = package.workbook
    header = %w[Ceinture Symbole Compétences]
    # students_list = @classroom.students.sort_by { |student| student.first_name.downcase }
    # header << students_list.map { |student| student.first_name.capitalize }
    # create a tab for each domain
    grade.domains.each do |domain|
      # all_completed_belts = Belt.includes([:student]).where(student: students_list, domain: domain, completed: true)

      workbook.add_worksheet(name: domain.name) do |sheet|
        sheet.add_row header.flatten
        skills.select { |skill| skill.domain == domain }.sort_by { |skill| [skill.level, skill.id] }.each do |skill|
          sheet.add_row [domain.special? ? "" : Belt::BELT_COLORS[skill.level - 1], skill.symbol, skill.name]
        end
      end
    end
    # Enregistrez le fichier XLSX dans un temp file et envoyez-le en tant que pièce jointe
    package
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
