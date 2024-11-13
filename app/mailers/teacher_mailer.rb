class TeacherMailer < ApplicationMailer
  def send_classroom_results_email(user, zipfile)
    @teacher = user
    attachments[File.basename(zipfile)] = File.read(zipfile)
    mail(to: @teacher.email, subject: 'Ensemble: Vos résultats sont prêts !')
  end
end
