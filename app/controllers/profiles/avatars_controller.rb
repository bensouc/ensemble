# frozen_string_literal: true

module Profiles
  # La photo du compte, enregistrée dès qu'on la choisit. À part du profil :
  # choisir une photo ne doit pas envoyer avec elle un prénom à moitié tapé.
  class AvatarsController < ApplicationController
    before_action { authorize current_user, :update? }

    def update
      if current_user.update(avatar: params.expect(user: [:avatar])[:avatar])
        redirect_to edit_profile_path, notice: t("mon_compte.photo_enregistree"), status: :see_other
      else
        redirect_to edit_profile_path, alert: current_user.errors.full_messages.to_sentence, status: :see_other
      end
    end

    def destroy
      current_user.avatar.purge_later
      redirect_to edit_profile_path, notice: t("mon_compte.photo_retiree"), status: :see_other
    end
  end
end
