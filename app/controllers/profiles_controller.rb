# frozen_string_literal: true

# La page « Mon compte ». Le prénom et le nom se changent sans mot de passe : ils
# ne donnent accès à rien. Devise l'exigeait pour tout, jusqu'à la photo.
# L'e-mail et le mot de passe restent à `RegistrationsController`.
class ProfilesController < ApplicationController
  before_action { authorize current_user }

  def edit
  end

  # Le profil s'enregistre dès qu'on quitte un champ, comme la photo dès qu'on la
  # choisit : par Turbo, sans bouton. Les réponses ne redessinent que ce qui
  # change — les avatars, dont les initiales suivent le nom, ou le champ refusé.
  # Recharger la page ferait perdre le champ où l'on vient d'entrer.
  def update
    if current_user.update(profile_params)
      flash.now[:notice] = t("mon_compte.profil_enregistre")
    else
      render :erreurs, status: :unprocessable_content
    end
  end

  private

  def profile_params
    params.expect(user: [:first_name, :last_name])
  end
end
