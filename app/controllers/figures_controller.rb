# frozen_string_literal: true

# Une figure n'appartient à personne et ne contient rien de privé : elle est
# entièrement décrite par ses paramètres (voir `Figure`). Pas de policy, donc.
class FiguresController < ApplicationController
  # Le sgid et le rendu d'édition d'une figure, que l'éditeur insère dans
  # l'énoncé en cours de rédaction.
  def create
    skip_authorization
    # L'éditeur envoie du JSON : `marge` et `chiffres` arrivent en vrais booléens,
    # pas en chaînes. Comparer à "true" ignorait la marge et la case « Chiffres ».
    id = Figure.id_for(kind: params[:kind], nom: params[:nom], heure: params[:heure],
                       chiffres: booleen(params[:chiffres], defaut: true), marge: booleen(params[:marge]))
    return render json: { error: "Heure invalide" }, status: :unprocessable_content unless id

    figure = Figure.find(id)
    # Mêmes clés que pour un tableau, et rien d'autre : le JS passe cette réponse
    # telle quelle à `new Trix.Attachment(...)`, tout ajout finirait sérialisé
    # dans le corps de l'énoncé.
    render json: {
      sgid: figure.attachable_sgid,
      contentType: figure.content_type,
      content: render_to_string(partial: "figures/editor", locals: { figure: }, formats: [:html])
    }
  end

  private

  def booleen(valeur, defaut: false)
    return defaut if valeur.nil?

    ActiveModel::Type::Boolean.new.cast(valeur)
  end
end
