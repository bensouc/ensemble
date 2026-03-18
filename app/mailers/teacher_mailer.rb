class TeacherMailer < ApplicationMailer
  include ApplicationHelper

  def send_classroom_results_email(user, classroom, download_url)
    @teacher = user
    @classroom = classroom
    @download_url = download_url
    mail(to: @teacher.email, subject: "Ensemble: Vos résultats sont prêts !")
  end
end
