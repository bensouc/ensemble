class ContactMailer < ApplicationMailer

  def new_contact(contact)
    @contact = contact
    mail(to: "contact@vroadstudio.fr", subject: "Nouveau contact")
  end
    def new_demo_user(contact)
    @contact = contact
    mail(to: "contact@vroadstudio.fr", subject: "Nouveau Compte Démo")
  end

  def add_user_to_school(user)
    @contact = user
    mail(to: @contact.email, subject: "Ensemble!  Bienvenue sur notre plateforme")
  end

private
# def contact_params
#   params.require(:contact).permit(:nom, :email, :school, :city, :message)
# end
end
