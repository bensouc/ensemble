# frozen_string_literal: true

module Manipule
  # Le tronc commun des écrans de l'enseignante.
  #
  # Manipule est une option ouverte compte par compte, le temps de l'essai :
  # sans elle, ces pages n'existent pas pour l'utilisateur. Le garde vit ici
  # plutôt que recopié dans chaque contrôleur, pour qu'on ne puisse pas en
  # ajouter un qui l'oublie.
  #
  # Il ne couvre que le côté enseignante. L'élève, lui, entre par le jeton de
  # sa classe — un jeton qui n'existe que si une enseignante l'a créé, donc si
  # elle avait l'option.
  class ProfController < ApplicationController
    before_action :exiger_l_option

    private

    def exiger_l_option
      return if current_user&.manipule_ouvert?

      redirect_to root_path, alert: t("manipule.option_fermee")
    end
  end
end
