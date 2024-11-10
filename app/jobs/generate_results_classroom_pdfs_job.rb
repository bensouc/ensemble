class GenerateResultsClassroomPdfsJob < ApplicationJob
  queue_as :default
  # This method performs the job of generating PDFs for each student in a classroom
  def perform(classroom)
    Rails.logger.info("Generating PDFs for classroom #{classroom.id}")
    students = classroom.students
    # Define the name of the zip file
    zipfile_name = "classroom_#{classroom.id}_students_pdfs.zip"
    temp_file = Tempfile.new(zipfile_name)
    begin
    # Create a new zip file
    Zip::OutputStream.open(temp_file) { |zos| } # Create a new zip file
    Rails.logger.info("Created empty zip file at #{temp_file.path}")
    # Open the zip file and add a PDF for each student
    Zip::File.open(temp_file.path, Zip::File::CREATE) do |zipfile|
      students.each do |student|
        pdf = PdfGenerator::StudentResultPdf.new(student).generate
        zipfile.get_output_stream("Progression de #{student.first_name}_#{Time.current.strftime("_%Y_%m_%d")}.pdf") { |f| f.write(pdf) }
      end
    end
      Rails.logger.info("Added PDFs to zip file for classroom #{classroom.id}")

      # Enregistrer le fichier ZIP dans public/downloads
      destination_path = Rails.root.join("tmp", zipfile_name)
      FileUtils.mv(temp_file.path, destination_path)
      Rails.logger.info("Moved zip file to #{destination_path}")

      # Vérifier que le fichier existe dans tmp
      if File.exist?(destination_path)
        Rails.logger.info("Zip file successfully created and moved to #{destination_path}")
      else
        Rails.logger.error("Failed to move zip file to #{destination_path}")
      end
    ensure
      # Ensure the temporary file is closed and unlinked
      temp_file.close
      temp_file.unlink
    end
  end
end
