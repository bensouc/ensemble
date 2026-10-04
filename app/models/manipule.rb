# frozen_string_literal: true

# Manipule : l'atelier d'entraînement autocorrigé de l'élève, à côté des plans
# de travail d'Ensemble et sans jamais s'y mêler.
#
# Le préfixe vaut pour les tables comme pour les classes. C'est ce qui rend la
# promesse tenable : supprimer Manipule, c'est supprimer ses tables et ce
# dossier.
module Manipule
  def self.table_name_prefix
    "manipule_"
  end
end
