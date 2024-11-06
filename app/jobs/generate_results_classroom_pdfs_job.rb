class GenerateResultsClassroomPdfsJob < ApplicationJob
  queue_as :default

def perform(classroom_id)
    classroom = Classroom.find(classroom_id)
    students = classroom.students

    zipfile_name = "classroom_#{classroom.id}_students_pdfs.zip"
    temp_file = Tempfile.new(zipfile_name)

    begin
      Zip::OutputStream.open(temp_file) { |zos| }

      Zip::File.open(temp_file.path, Zip::File::CREATE) do |zipfile|
        students.each do |student|
          pdf = PdfGenerator::StudentResultPdf.new(student).generate
          zipfile.get_output_stream("Progression de #{student.first_name} - #{Time.now.strftime("%d/%m/%Y")}.pdf") { |f| f.write(pdf) }
        end
      end

      # Enregistrer le fichier ZIP dans un emplacement accessible
      FileUtils.mv(temp_file.path, Rails.root.join('public', 'downloads', zipfile_name))
    ensure
      temp_file.close
      temp_file.unlink
    end
  end
end
