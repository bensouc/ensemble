# frozen_string_literal: true

module Ui
  # Le bouton d'Ensemble. Ses variantes sont celles de la refonte des plans de
  # travail — la pastille `pill-cta` et ses déclinaisons —, rassemblées au lieu
  # d'être recopiées en classes CSS d'un écran à l'autre :
  #
  # - `:primary`   l'action principale (Valider) : rose plein ;
  # - `:secondary` les actions d'ajout et de remplacement (Ajouter, Cloner,
  #                Charger) : pastille rose à 8 %, pleine au survol ;
  # - `:neutral`   sortir sans rien faire (Annuler) : la même pastille, en gris ;
  # - `:success`   la pastille verte ;
  # - `:icon`      une icône seule, dans un rond (le ⋮ d'un menu d'actions).
  #
  # Quatre formes, selon ce qu'on lui donne : un lien (`href:`), un formulaire
  # d'un bouton (`url:`, comme `button_to`), l'étiquette d'un champ
  # (`label_for:`, qui ouvre un sélecteur de fichier sans JavaScript), ou un
  # simple `<button>`.
  #
  #   render Ui::ButtonComponent.new("Annuler", variant: :neutral, data: { bs_dismiss: "modal" })
  #   render Ui::ButtonComponent.new("Valider", variant: :primary, type: "submit")
  #   render Ui::ButtonComponent.new("Cloner", icon: "fa-regular fa-clone", url: duplicate_path(x))
  #   render Ui::ButtonComponent.new("Changer la photo", icon: "fa-camera", label_for: "compte-photo")
  class ButtonComponent < ViewComponent::Base
    VARIANTS = %i[primary secondary neutral success icon].freeze
    SIZES = %i[sm md lg].freeze

    # Une affectation par option, rien d'autre : la longueur vient du nombre d'options.
    # rubocop:disable Metrics/ParameterLists, Metrics/MethodLength
    def initialize(label = nil, variant: :secondary, size: :md, icon: nil, href: nil, url: nil, method: :post,
                   label_for: nil, type: "button", title: nil, data: {}, form: {}, html: {})
      # rubocop:enable Metrics/ParameterLists
      super()
      raise ArgumentError, "variante inconnue : #{variant}" unless VARIANTS.include?(variant)
      raise ArgumentError, "taille inconnue : #{size}" unless SIZES.include?(size)

      @label = label
      @variant = variant
      @size = size
      @icon = icon
      @href = href
      @url = url
      @method = method
      @label_for = label_for
      @type = type
      @title = title
      @data = data
      @form = form
      @html = html
    end
    # rubocop:enable Metrics/MethodLength

    def call
      if @href
        link_to(@href, **attributes) { inner }
      elsif @url
        button_to(@url, method: @method, form: @form, **attributes) { inner }
      elsif @label_for
        tag.label(for: @label_for, **attributes) { inner }
      else
        button_tag(type: @type, **attributes) { inner }
      end
    end

    private

    def inner
      safe_join([icon_tag, label_tag].compact)
    end

    def icon_tag
      return unless @icon

      # « fa-clone » seul vaut l'icône pleine ; une famille donnée est respectée.
      classes = @icon.include?(" ") ? @icon : "fa-solid #{@icon}"
      tag.i(class: classes, aria: { hidden: true })
    end

    def label_tag
      text = @label || content
      tag.span(text) if text.present?
    end

    # Une icône seule n'a pas de texte à lire : son `title` en tient lieu.
    def attributes
      attrs = { class: css_classes, title: @title, data: @data }.merge(@html.except(:class))
      attrs[:aria] = { label: @title } if @title && @label.nil? && content.blank?
      attrs
    end

    def css_classes
      ["ui-btn", "ui-btn--#{@variant}", ("ui-btn--#{@size}" unless @size == :md), @html[:class]].compact.join(" ")
    end
  end
end
