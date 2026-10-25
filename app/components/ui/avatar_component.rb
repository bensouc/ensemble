# frozen_string_literal: true

module Ui
  # L'avatar d'un compte : sa photo, ou ses initiales dans un rond de couleur.
  #
  # - `size:` `:sm` un message, `:md` une conversation, `:lg` la barre du haut,
  #   `:xl` la page « Mon compte » ;
  # - `logo:` le logo d'Ensemble à la place de la personne. La messagerie le
  #   demande pour un admin, qui y parle au nom d'Ensemble.
  #
  #   render Ui::AvatarComponent.new(current_user, size: :lg)
  #   render Ui::AvatarComponent.new(message.user, size: :sm, logo: message.user.admin?)
  class AvatarComponent < ViewComponent::Base
    SIZES = { sm: 25, md: 40, lg: 55, xl: 96 }.freeze
    # Autant que les `.ui-avatar--teinte-*` de `components/_ui_avatar.scss`.
    TEINTES = 3
    LOGO = "icons/vroad_b_w.png"

    def initialize(user, size: :md, logo: false, html: {})
      super()
      raise ArgumentError, "taille inconnue : #{size}" unless SIZES.key?(size)

      @user = user
      @size = size
      @logo = logo
      @html = html
    end

    def call
      if @logo
        image_tag(LOGO, alt: "Ensemble", **attributes)
      elsif @user.avatar.attached?
        image_tag(photo_url, alt: @user.display_name, **attributes)
      else
        tag.span(initiales, role: "img", aria: { label: @user.display_name }, **attributes(teinte))
      end
    end

    private

    # Le double de la taille affichée, pour les écrans à haute densité.
    # `gravity: :face` recadre sur le visage plutôt qu'au centre de la photo.
    def photo_url
      cote = SIZES[@size] * 2
      Cloudinary::Utils.cloudinary_url(@user.avatar.key, width: cote, height: cote, crop: :fill, gravity: :face,
                                                         fetch_format: :auto, quality: :auto)
    end

    # Un invité n'a encore ni prénom ni nom : l'email est tout ce qu'on sait de lui.
    def initiales
      lettres = [@user.first_name, @user.last_name].filter_map { |part| part.to_s.strip.first.presence }
      (lettres.presence || [@user.email.to_s.first]).join.upcase
    end

    def teinte
      "ui-avatar--teinte-#{@user.id.to_i % TEINTES}"
    end

    def attributes(teinte = nil)
      { class: class_names("ui-avatar", "ui-avatar--#{@size}", teinte, @html[:class]) }.merge(@html.except(:class))
    end
  end
end
