# frozen_string_literal: true

# La page « Mon compte ». Le prénom et le nom se changent sans mot de passe : ils
# ne donnent accès à rien. Devise l'exigeait pour tout, jusqu'à la photo.
# L'e-mail et le mot de passe restent à `RegistrationsController`.
class ProfilesController < ApplicationController
  before_action { authorize current_user }

  def edit
  end

  # Le profil s'enregistre dès qu'on quitte un champ, comme la photo dès qu'on la
  # choisit. La réponse ne redessine que les avatars, dont les initiales suivent
  # le nom : recharger la page ferait perdre le champ où l'on vient d'entrer.
  def update
    if current_user.update(profile_params)
      message = t("mon_compte.profil_enregistre")
      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = message }
        format.html { redirect_to edit_profile_path, notice: message, status: :see_other }
      end
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def profile_params
    params.expect(user: [:first_name, :last_name])
  end
end
