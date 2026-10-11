# frozen_string_literal: true

module Ui
  # La mise en page commune des écrans de « Voir » : un titre, les onglets de la
  # section, puis le contenu de la page. Plans de travail et Ceintures ont chacun
  # deux onglets — leur liste, et leurs exercices.
  #
  #   render Ui::PageComponent.new(title: "Plans de travail", tabs: onglets_plans_de_travail(:plans)) do
  #     …le contenu…
  #   end
  #
  # `actions` : de quoi poser un bouton à droite du titre.
  class PageComponent < ViewComponent::Base
    renders_one :actions

    def initialize(title:, tabs: [])
      super()
      @title = title
      @tabs = tabs
    end

    def call
      tag.div(class: "ui-page") do
        safe_join([entete, (render(TabsComponent.new(tabs: @tabs, label: @title)) if @tabs.any?), content].compact)
      end
    end

    private

    def entete
      tag.header(class: "ui-page-header") do
        titre = tag.h1(@title, class: "ui-page-title")
        actions? ? safe_join([titre, tag.div(actions, class: "ui-page-actions")]) : titre
      end
    end
  end
end
