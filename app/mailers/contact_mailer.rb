class ContactMailer < ApplicationMailer

  def new_contact(contact)
    @contact = contact
    mail(to: "contact@vroadstudio.fr", subject: "Nouveau contact")
  end

private
# def contact_params
#   params.require(:contact).permit(:nom, :email, :school, :city, :message)
# end
end
