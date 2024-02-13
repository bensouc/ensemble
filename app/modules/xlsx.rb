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
end
