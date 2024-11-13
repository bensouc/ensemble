class GenerateResultsClassroomPdfsJob < ApplicationJob
  queue_as :default
  # This method performs the job of generating PDFs for each student in a classroom
  #
  def perform(classroom, user_id)
    Rails.logger.info("Generating PDFs for classroom #{classroom.id}")
    students = classroom.students
    # Define the name of the zip file
    zipfile_name = "classroom_#{classroom.id}_students_pdfs.zip"
    temp_file = Tempfile.new(zipfile_name)

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
    # send an email to the user with the zip file attached
    TeacherMailer.send_classroom_results_email(User.find(user_id), temp_file).deliver_now
    # Turbo::StreamChannel.broadcast_to("user_#{user_id}", action: "download_ready", url: "/downloads/#{zipfile_name}")
  end
end
