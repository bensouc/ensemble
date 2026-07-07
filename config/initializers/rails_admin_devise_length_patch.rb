# frozen_string_literal: true
#
# Compat rails_admin 3.3.0  <->  Devise >= 4.9 (ici 5.0.4)
#
# Depuis Devise 4.9, les bornes de longueur du mot de passe sont enregistrées
# comme des Procs et non plus comme des entiers :
#
#   validates_length_of :password,
#     minimum: proc { password_length.min },
#     maximum: proc { password_length.max }, allow_blank: true
#
# rails_admin 3.3.0 lit ces bornes dans String#generic_help puis les compare à
# des entiers pour construire le texte d'aide sous le champ :
#
#   max_length = [length, valid_length[:maximum] || nil].compact.min
#   min_length = [0, valid_length[:minimum] || nil].compact.max   # 0 <=> Proc
#
# La comparaison Integer <=> Proc lève « comparison of Integer with Proc failed »
# et casse /admin/<model>/new et /edit pour tout modèle Devise (User).
#
# On résout ici les bornes Proc en entiers avant qu'elles n'atteignent le code
# de rendu. Purement défensif : si la résolution échoue on retombe sur nil, et
# generic_help gère nil sans problème.
RailsAdmin::Config::Fields::Base.class_eval do
  register_instance_option :valid_length do
    @valid_length ||= begin
      options = abstract_model.model.validators_on(name).detect { |v| v.kind == :length }.try(&:options) || {}
      options.transform_values do |value|
        next value unless value.is_a?(Proc)

        begin
          record = (bindings && bindings[:object]) || abstract_model.model.new
          record.instance_exec(&value)
        rescue StandardError
          nil
        end
      end
    end
  end
end
