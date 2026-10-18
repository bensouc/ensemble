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

  # Le catalogue du matériel, pour l'éditeur de zone (editeur/zone.js) : chaque
  # élément avec son dessin, en image, et sa taille en pas de la grille.
  def materiel
    skip_authorization
    render json: {
      pas: Figure::Zone::PAS_DE_LA_GRILLE,
      largeurs: Figure::Zone::LARGEURS.minmax, hauteurs: Figure::Zone::HAUTEURS.minmax,
      elementsAuPlus: Figure::Zone::ELEMENTS_AU_PLUS,
      elements: Figure::Zone::CODES.transform_values { |id| element_du_catalogue(Figure.find(id)) }
    }
  end

  private

  def element_du_catalogue(figure)
    largeur, hauteur = figure.taille_du_materiel.map { |em| (em / Figure::Zone::PAS_DE_LA_GRILLE).round(2) }
    svg = render_to_string(partial: "figures/#{figure.kind}_svg", locals: { dessinable: figure }, formats: [:html])
    { libelle: figure.libelle, sorte: figure.kind, largeur:, hauteur:,
      image: "data:image/svg+xml;base64,#{Base64.strict_encode64(svg.strip)}" }
  end

  def booleen(valeur, defaut: false)
    return defaut if valeur.nil?

    ActiveModel::Type::Boolean.new.cast(valeur)
  end
end
