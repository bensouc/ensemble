# frozen_string_literal: true

# L'éditeur d'exercice est TipTap (il remplace Trix, pour tout le monde).
#
# Le stockage ne change pas : c'est toujours un corps ActionText. TipTap reçoit
# ce que Rails donne à Trix (`to_trix_html`) et renvoie le même format de pièce
# jointe (`<figure data-trix-attachment>`), que Rails convertit comme avant à
# l'enregistrement. Mesuré sur les 2 904 énoncés de la base : 2 900 ressortent
# identiques d'un aller-retour, les 4 autres changent du seul fait de Rails.
#
# Les tableaux maison (modèle `Table`) deviennent des tableaux natifs au fil de
# l'eau : à l'ouverture d'un énoncé dans l'éditeur, puis pour de bon à son
# enregistrement. Un énoncé jamais rouvert garde son tableau maison, qui
# s'affiche comme avant.
module EditeurTiptap
  module_function

  # Ce que reçoit l'éditeur : le corps au format Trix, tableaux maison convertis,
  # adresses des images rafraîchies.
  #
  # Le vide se juge sur le HTML, pas sur `body.blank?` : ActionText juge un corps
  # par son texte brut, et un énoncé fait d'un seul tableau n'en a pas. Il
  # s'ouvrait vide, et l'enregistrement l'effaçait.
  def contenu_initial(rich_text)
    html = rich_text&.body&.to_html.to_s
    return "" if html.strip.empty?

    ActionText::Content.new(adresses_rafraichies(tableaux_convertis(html))).to_trix_html
  end

  # L'éditeur affiche une image à l'adresse enregistrée avec elle, figée au jour
  # de l'envoi : `http://127.0.0.1:3000/…` pour un exercice créé en local, un
  # ancien domaine pour un très vieil exercice. Quand Rails retrouve l'image, on
  # lui donne une adresse relative, valable quel que soit le serveur. Une image
  # introuvable garde la sienne : c'est la seule qu'on ait.
  def adresses_rafraichies(html)
    ActionText::Fragment.wrap(html).update do |source|
      source.css("action-text-attachment[sgid][url]").each do |node|
        blob = blob_pour(node["sgid"])
        node["url"] = Rails.application.routes.url_helpers.rails_blob_path(blob, only_path: true) if blob
      end
    end.to_html
  end

  def blob_pour(sgid)
    ActiveStorage::Blob.from_attachable_sgid(sgid)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  # Remplace chaque pièce jointe tableau par un tableau HTML de même contenu.
  # Un sgid illisible (signé ailleurs, tableau disparu) laisse la pièce jointe
  # telle quelle : TipTap la conserve sans y toucher.
  def tableaux_convertis(html)
    ActionText::Fragment.wrap(html).update do |source|
      source.css("action-text-attachment[sgid]").each do |node|
        table = table_pour(node["sgid"])
        node.replace(Nokogiri::HTML5.fragment(html_du_tableau(table))) if table
      end
    end.to_html
  end

  def table_pour(sgid)
    Table.from_attachable_sgid(sgid)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  # Mêmes classes que le rendu du tableau maison (`tables/_table`) : à l'écran et
  # dans le PDF, le tableau converti a la même allure. Le style des cases suit :
  # gras, italique, souligné, couleur, alignement de la colonne — perdu, l'en-tête
  # ou les mots mis en valeur d'un tableau redevenaient du texte ordinaire.
  def html_du_tableau(table)
    lignes = (0...table.rows).map do |r|
      balise = r.zero? && table.header_row? ? "th" : "td"
      cellules = (0...table.columns).map do |c|
        %(<#{balise} class="rt-cell">#{paragraphe_de_case(table, r, c)}</#{balise}>)
      end
      "<tr>#{cellules.join}</tr>"
    end
    %(<table class="rt-table__grid"><tbody>#{lignes.join}</tbody></table>)
  end

  def paragraphe_de_case(table, ligne, colonne)
    texte = table.cell(ligne, colonne).to_s.split("\n", -1).map { |l| ERB::Util.html_escape(l) }.join("<br>")
    texte = mise_en_valeur(texte, table, ligne, colonne) if texte.present?
    alignement = table.align_for(colonne)
    style = %( style="text-align: #{alignement}") unless alignement == "left"
    "<div#{style}>#{texte}</div>"
  end

  # Couleur (palette de Table seulement) et marques, de l'extérieur vers
  # l'intérieur, comme les écrit l'éditeur.
  def mise_en_valeur(texte, table, ligne, colonne)
    styles = table.styles_for(ligne, colonne)
    texte = "<u>#{texte}</u>" if styles.include?("u")
    texte = "<em>#{texte}</em>" if styles.include?("i")
    texte = "<strong>#{texte}</strong>" if styles.include?("b")
    couleur = table.color_for(ligne, colonne)
    couleur ? %(<span style="color: #{couleur}">#{texte}</span>) : texte
  end
end
