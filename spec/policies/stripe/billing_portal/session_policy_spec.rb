# frozen_string_literal: true

require "rails_helper"

# La règle était `!record.nil?`, donc toujours vraie : n'importe quel enseignant
# connecté pouvait ouvrir `/create-customer-portal-session` et **résilier**
# l'abonnement de son groupe. Le menu ne faisait que cacher le bouton.
RSpec.describe Stripe::BillingPortal::SessionPolicy do
  let(:school) { create(:school, stripe_customer_id: "cus_test") }
  let(:responsable) { create(:user, admin: false, demo: false) }
  let(:collegue) { create(:user, admin: false, demo: false) }
  let(:admin) { create(:user, admin: true) }

  before do
    school.add_teacher(responsable, true)
    school.add_teacher(collegue)
  end

  def autorise?(user)
    described_class.new(user.reload, Stripe::BillingPortal::Session.new).create_portal_session?
  end

  it "ouvre le portail au responsable du groupe" do
    expect(autorise?(responsable)).to be true
  end

  it "le ferme à un enseignant ordinaire du groupe" do
    expect(autorise?(collegue)).to be false
  end

  # Le compte de support n'a pas d'abonnement à gérer, et `current_user.school`
  # désignerait sa propre école de test. Pour accompagner une école, un admin la
  # personnifie — voir la spec de personnification.
  it "le ferme à un admin sur son propre compte" do
    expect(autorise?(admin)).to be false
  end

  # `school_role` peut manquer : inscription abandonnée avant la création de
  # l'école. `super_teacher?` doit répondre false, pas lever.
  it "le ferme à un compte sans école" do
    orphelin = create(:user, admin: false, demo: false)
    orphelin.school_role&.destroy
    expect(autorise?(orphelin)).to be false
  end
end
