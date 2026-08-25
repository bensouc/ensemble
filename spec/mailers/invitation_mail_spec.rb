# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Mail d'invitation" do
  include ActiveSupport::Testing::TimeHelpers

  let(:school) { create(:school, name: "école du centre") }
  let(:responsable) { create(:user, admin: false, demo: false, first_name: "claire ") }

  # Le corps part en quoted-printable : sans décodage, les accents et les
  # retours à la ligne cassent chaque assertion.
  def corps_decode(mail)
    mail.body.encoded.gsub("=\r\n", "").
      gsub(/=([0-9A-F]{2})/) { [Regexp.last_match(1)].pack("H*") }.force_encoding("UTF-8")
  end

  before do
    school.add_teacher(responsable, true)
    travel_to(Time.zone.local(2026, 8, 25, 10, 0)) do
      school.invite_teacher("collegue@ecole.fr", responsable.reload)
    end
  end

  let(:mail) { ActionMailer::Base.deliveries.last }
  let(:corps) { corps_decode(mail) }
  # Les phrases traversent le balisage (`<strong>Claire</strong> vous invite`) :
  # on lit ce que le destinataire lit.
  let(:texte) { corps.gsub(/<[^>]+>/, " ").gsub(/\s+/, " ").strip }

  it "part à l'invité, sous un objet qui nomme l'école" do
    expect(mail.to).to eq(["collegue@ecole.fr"])
    expect(mail.subject).to eq("Ensemble : vous êtes invité(e) à rejoindre École du centre")
  end

  it "nomme l'école et l'invitant, sans traîner l'espace de son prénom" do
    expect(texte).to include("Claire vous invite à rejoindre le groupe École du centre")
    expect(texte).not_to include("Claire  ")
  end

  # `config.invite_for = 15.days` : le mail suit la config, il ne la répète pas.
  it "annonce la durée de validité et la date d'expiration" do
    expect(texte).to include("valable 15 jours")
    expect(texte).to include("expire le 9 septembre 2026")
  end

  it "porte le logo Ensemble et le lien d'acceptation" do
    expect(corps).to include("ensemble_icone")
    expect(corps).to match(%r{users/invitation/accept\?invitation_token=})
  end

  # Un href sans schéma est relatif : mort dans un client mail.
  it "n'a que des liens absolus" do
    liens = corps.scan(/href="([^"]+)"/).flatten
    expect(liens).to all(match(%r{\Ahttps?://}))
  end
end
