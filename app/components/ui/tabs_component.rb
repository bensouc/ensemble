# frozen_string_literal: true

module Ui
  # Des onglets : des liens, et un soulignement fin sous celui de la page
  # courante — le modèle de la barre de Manipule (`.m-onglets`), jamais une
  # pastille pleine. Le menu de gauche marque l'entrée courante par la couleur,
  # les onglets font de même.
  #
  #   render Ui::TabsComponent.new(tabs: [
  #     { label: "Exercices", href: challenges_path, active: true },
  #     { label: "Exercices de ceinture", href: challenges_path(ceinture: 1) }
  #   ])
  class TabsComponent < ViewComponent::Base
    def initialize(tabs:, label: nil)
      super()
      @tabs = tabs
      @label = label
    end

    def call
      tag.nav(class: "ui-tabs", aria: { label: @label }) do
        tag.ul do
          safe_join(@tabs.map { |tab| tag.li { lien(tab) } })
        end
      end
    end

    private

    def lien(tab)
      link_to(tab[:label], tab[:href], class: ("ui-tabs-active" if tab[:active]),
                                       aria: { current: ("page" if tab[:active]) })
    end
  end
end
