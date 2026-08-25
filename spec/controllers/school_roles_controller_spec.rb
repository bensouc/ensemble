# frozen_string_literal: true

require "rails_helper"

RSpec.describe SchoolRolesController, type: :controller do
  let(:school) { create(:school, name: "École du Centre") }
  let(:newcomer) { create(:user, admin: false, demo: true) }

  def join_with(code)
    post :create, params: { new_sub: { school_code: code } }
  end

  before { sign_in(newcomer) }

  describe "avec un code valide" do
    it "fait basculer l'enseignant dans l'école" do
      join_with(school.code)
      expect(newcomer.reload.school).to eq(school)
      expect(response).to redirect_to(dashboard_path)
      expect(flash[:notice]).to include("École du Centre")
    end

    # `has_one :school_role` : deux lignes en base, et l'enseignant se serait
    # retrouvé dans l'école de démonstration une fois sur deux.
    it "remplace le rôle précédent au lieu d'en empiler un second" do
      expect { join_with(school.code) }.not_to change(SchoolRole, :count)
      expect(SchoolRole.where(user: newcomer).count).to eq(1)
    end

    it "n'est plus un compte de démonstration" do
      expect { join_with(school.code) }.to change { newcomer.reload.demo }.to(false)
    end

    it "rejoint comme membre, pas comme responsable" do
      join_with(school.code)
      expect(newcomer.reload.school_role.super_teacher).to be_falsey
    end

    it "accepte le code dicté en minuscules, espaces compris" do
      join_with("  #{school.code.downcase}  ")
      expect(newcomer.reload.school).to eq(school)
    end
  end

  describe "avec un code inconnu" do
    # `authorize nil` levait une Pundit::NotDefinedError : une faute de frappe
    # sur le code répondait par une erreur 500.
    it "renvoie sur l'écran de saisie avec un message, sans planter" do
      school
      expect { join_with("ZZZZZZ") }.not_to raise_error
      expect(response).to redirect_to(join_school_path)
      expect(flash[:alert]).to match(/code école inconnu/i)
    end

    it "laisse le compte là où il était" do
      original = newcomer.school
      join_with("ZZZZZZ")
      expect(newcomer.reload.school).to eq(original)
      expect(newcomer.demo).to be true
    end

    # Une école dont le code manque encore ne doit pas devenir la destination
    # par défaut de toutes les saisies vides.
    it "ne prend pas une saisie vide pour un code d'école" do
      school.update_column(:code, nil)
      join_with("")
      expect(response).to redirect_to(join_school_path)
      expect(newcomer.reload.school).not_to eq(school)
    end
  end
end
