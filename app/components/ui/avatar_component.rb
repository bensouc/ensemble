# frozen_string_literal: true

module Ui
  # L'avatar d'un compte : sa photo, ou ses initiales dans un rond de couleur.
  #
  # - `size:` `:sm` (25 px, un message), `:md` (40 px, une conversation), `:lg`
  #   (55 px, la barre du haut), `:xl` (96 px, la page « Mon compte ») ;
  # - `logo_pour_admin:` montre un admin sous le logo d'Ensemble. La messagerie
  #   seule le demande : un admin y parle au nom d'Ensemble. Ailleurs, il a son
  #   avatar comme tout le monde.
  #
  #   render Ui::AvatarComponent.new(current_user, size: :lg)
  #   render Ui::AvatarComponent.new(message.user, size: :sm, logo_pour_admin: true)
  class AvatarComponent < ViewComponent::Base
    SIZES = { sm: 25, md: 40, lg: 55, xl: 96 }.freeze
    # Autant que la liste `$avatar-teintes` de la palette.
    TEINTES = 3
    LOGO = "icons/vroad_b_w.png"

    def initialize(user, size: :md, logo_pour_admin: false, html: {})
      super()
      raise ArgumentError, "taille inconnue : #{size}" unless SIZES.key?(size)

      @user = user
      @size = size
      @logo_pour_admin = logo_pour_admin
      @html = html
    end

    def call
      if @logo_pour_admin && @user.admin?
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

    def attributes(*classes)
      { class: ["ui-avatar", "ui-avatar--#{@size}", *classes, @html[:class]].compact.join(" ") }.
        merge(@html.except(:class))
    end
  end
end
