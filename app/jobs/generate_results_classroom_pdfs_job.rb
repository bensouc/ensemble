class GenerateResultsClassroomPdfsJob < ApplicationJob
  include ApplicationHelper

  queue_as :pdf
  # This method performs the job of generating PDFs for each student in a classroom
  def perform(classroom, user_id)
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
        # Un browser neuf par élève : Chrome single-process accumule la mémoire
        # et finit par ne plus répondre dans le container
        students.each do |student|
          Rails.logger.info("[PdfGenerator] Génération PDF pour #{student.first_name} (id: #{student.id})")
          pdf = PdfGenerator::StudentResultPdf.new(student).generate
          zipfile.get_output_stream("Progression de #{I18n.transliterate(student.first_name).capitalize}_#{Time.current.strftime('_%Y_%m_%d')}.pdf") do |f|
            f.write(pdf)
          end
        end
      end
      Rails.logger.info("Added PDFs to zip file for classroom #{classroom.id}")

      # Enregistrer le fichier ZIP dans public/downloads
      # destination_path = Rails.root.join("tmp", zipfile_name)

      # Upload ZIP sur Cloudinary (raw) et envoyer le lien par email
      upload = Cloudinary::Uploader.upload(
        temp_file.path,
        resource_type: "raw",
        folder: "ensemble/results",
        public_id: "resultats_classe_#{classroom.id}_#{Time.current.strftime('%Y_%m_%d')}",
        overwrite: true
      )
      # URL signée valide 7 jours
      download_url = Cloudinary::Utils.cloudinary_url(
        upload["public_id"],
        resource_type: "raw",
        type: "upload",
        sign_url: true,
        expires_at: 7.days.from_now.to_i
      )
      Rails.logger.info("[PdfGenerator] ZIP uploadé sur Cloudinary: #{download_url}")

      TeacherMailer.send_classroom_results_email(User.find(user_id), classroom, download_url).deliver_now

      # Ensure the temporary file is closed and unlinked
      temp_file.close
      temp_file.unlink
    end
  end
end
