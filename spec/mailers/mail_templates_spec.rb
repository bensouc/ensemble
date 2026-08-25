# frozen_string_literal: true

require "rails_helper"

# Tous les envois passent par le même gabarit : un seul jeu d'assertions vaut
# pour tous. Trois d'entre eux rendaient auparavant leur propre coquille HTML,
# imbriquée dans celle du gabarit — et en police à empattement par défaut.
RSpec.describe "Gabarits de mail" do
  let(:school) { create(:school, name: "École du Centre") }
  let(:teacher) { create(:user, admin: false, demo: false, first_name: "Claire") }
  let(:contact) do
    { first_name: "Camille", last_name: "Perrin", email: "camille@ecole.fr", school: "Jean Moulin",
      city: "Nantes", discovery_method: "Bouche-à-oreille", message: "Bonjour.", type: "Ajout de classes" }
  end

  def corps(mail) = mail.body.decoded.dup.force_encoding("UTF-8")

  before { school.add_teacher(teacher, true) }

  def tous_les_mails
    invite = school.invite_teacher("collegue@ecole.fr", teacher.reload)
    classroom = create(:classroom, user: teacher)
    {
      "invitation" => InvitationMailer.invitation_instructions(invite, invite.raw_invitation_token),
      "mot de passe oublié" => InvitationMailer.reset_password_instructions(teacher, "jeton"),
      "mot de passe modifié" => InvitationMailer.password_change(teacher),
      "email modifié" => InvitationMailer.email_changed(teacher),
      "résultats de classe" => TeacherMailer.send_classroom_results_email(teacher, classroom, "https://x.fr/r.zip"),
      "nouveau contact" => ContactMailer.new_contact(contact),
      "nouveau compte démo" => ContactMailer.new_demo_user(contact),
      "nouvelle demande" => ContactMailer.new_request(contact)
    }
  end

  it "rendent tous, sous la même coquille" do
    tous_les_mails.each do |nom, mail|
      html = corps(mail)
      expect(html).to include("ensemble_icone"), "#{nom} : logo absent"
      expect(html).to include("font-family:-apple-system"), "#{nom} : styles non inlinés"
      expect(html).to include("max-width:600px"), "#{nom} : carte absente"
      expect(mail.subject).to be_present, "#{nom} : sans objet"
    end
  end

  # Les gabarits portaient leur propre <html><body>, imbriqué dans celui du
  # gabarit partagé.
  it "ne redoublent pas la structure du document" do
    tous_les_mails.each do |nom, mail|
      expect(corps(mail).scan(/<html/i).size).to eq(1), "#{nom} : <html> en double"
      expect(corps(mail).scan(/<body/i).size).to eq(1), "#{nom} : <body> en double"
    end
  end

  # Trois d'entre eux s'adressaient au destinataire en anglais.
  it "s'adressent au lecteur en français" do
    tous_les_mails.each do |nom, mail|
      expect(corps(mail)).not_to match(/\bHello\b|We're contacting you|Thanks for joining/), "#{nom} : texte anglais"
    end
  end
end
