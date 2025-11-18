class ContactMailer < ApplicationMailer

  def new_contact(contact)
    @contact = contact
    mail(to: "bensoucdev@gmail.com", subject: "Nouveau contact")
  end
    def new_demo_user(contact)
    @contact = contact
    mail(to: "bensoucdev@gmail.com", subject: "Nouveau Compte Démo")
  end

  def add_user_to_school(user)
    @contact = user
    mail(to: @contact.email, subject: "Ensemble!  Bienvenue sur notre plateforme")
  end

  def new_request(user_request)
    @user_request = user_request
    mail(to: "bensoucdev@gmail.com", subject: "Nouvelle demande")
  end

private
# def contact_params
#   params.require(:contact).permit(:nom, :email, :school, :city, :message)
# end
end
