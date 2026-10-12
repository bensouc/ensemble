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

  # Ce que reçoit l'éditeur : le corps au format Trix, tableaux maison convertis.
  #
  # Le vide se juge sur le HTML, pas sur `body.blank?` : ActionText juge un corps
  # par son texte brut, et un énoncé fait d'un seul tableau n'en a pas. Il
  # s'ouvrait vide, et l'enregistrement l'effaçait.
  def contenu_initial(rich_text)
    html = rich_text&.body&.to_html.to_s
    return "" if html.strip.empty?

    ActionText::Content.new(tableaux_convertis(html)).to_trix_html
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
  # dans le PDF, le tableau converti a la même allure.
  def html_du_tableau(table)
    lignes = (0...table.rows).map do |r|
      balise = r.zero? && table.header_row? ? "th" : "td"
      cellules = (0...table.columns).map do |c|
        texte = ERB::Util.html_escape(table.cell(r, c).to_s)
        %(<#{balise} class="rt-cell"><div>#{texte}</div></#{balise}>)
      end
      "<tr>#{cellules.join}</tr>"
    end
    %(<table class="rt-table__grid"><tbody>#{lignes.join}</tbody></table>)
  end
end
