class TeacherMailer < ApplicationMailer
  include ApplicationHelper

  def send_classroom_results_email(user, classroom, zipfile)
    @teacher = user
    attachments[sanitize_filename("resultats_#{Time.current.strftime("_%Y_%m_%d_")}classe_ #{classroom.safe_name}_students_pdfs")+'.zip'] = File.read(zipfile)
    mail(to: @teacher.email, subject: 'Ensemble: Vos résultats sont prêts !')
  end
end
