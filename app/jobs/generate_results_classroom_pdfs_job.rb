class GenerateResultsClassroomPdfsJob < ApplicationJob
  queue_as :default
  # This method performs the job of generating PDFs for each student in a classroom
  def perform(classroom)
    Rails.logger.info("Generating PDFs for classroom #{classroom.id}")
    students = classroom.students
    # Define the name of the zip file
    zipfile_name = "classroom_#{classroom.id}_students_pdfs.zip"
    temp_file = Tempfile.new(zipfile_name)

    # Create a new zip file
    Zip::OutputStream.open(temp_file) { |zos| } # Create a new zip file
    # Open the zip file and add a PDF for each student
    Zip::File.open(temp_file.path, Zip::File::CREATE) do |zipfile|
      students.each do |student|
        pdf = PdfGenerator::StudentResultPdf.new(student).generate
        zipfile.get_output_stream("Progression de #{student.first_name}_#{Time.current.strftime("_%Y_%m_%d")}.pdf") { |f| f.write(pdf) }
      end
    end

    # Enregistrer le fichier ZIP dans public/downloads
    FileUtils.mv(temp_file.path, Rails.root.join("tmp", zipfile_name))

    # Ensure the temporary file is closed and unlinked
    # # même si une exception est levée est levée dans le bloc begin
    # temp_file.close
    # temp_file.unlink
  end
end
