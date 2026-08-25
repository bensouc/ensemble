# frozen_string_literal: true

# Les clients mail ignorent l'essentiel des feuilles de style : chaque règle doit
# voyager dans un attribut `style`. Ces méthodes évitent de les recopier dans
# chaque gabarit, et surtout de les laisser diverger d'un envoi à l'autre.
module MailStylesHelper
  POLICE = "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif"
  ROSE = "#f24150"

  REGLES = {
    titre: "margin:0 0 10px 0; font-size:21px; line-height:1.35; font-weight:700; color:#1d1d1f;",
    texte: "margin:0 0 14px 0; font-size:15px; line-height:1.65; color:#515154;",
    note: "margin:0 0 10px 0; font-size:13px; line-height:1.6; color:#86868b;",
    petit: "margin:0; font-size:12px; line-height:1.6; color:#a1a1a6; word-break:break-all;",
    etiquette: "margin:0 0 2px 0; font-size:11px; line-height:1.5; color:#a1a1a6; " \
               "text-transform:uppercase; letter-spacing:0.07em;",
    valeur: "margin:0 0 16px 0; font-size:15px; line-height:1.5; color:#1d1d1f;"
  }.freeze

  def mail_style(nom)
    "font-family:#{POLICE}; #{REGLES.fetch(nom)}"
  end

  # Un `<a>` mis en bloc ne s'affiche pas de la même façon d'un client à l'autre :
  # seule une cellule de tableau colorée tient partout, Outlook compris.
  def mail_button(libelle, url)
    tag.table(role: "presentation", cellpadding: 0, cellspacing: 0, border: 0, style: "margin:0 auto;") do
      tag.tr do
        tag.td(align: "center", bgcolor: ROSE, style: "border-radius:10px;") do
          link_to(libelle, url,
                  style: "display:inline-block; padding:14px 32px; font-family:#{POLICE}; font-size:16px; " \
                         "font-weight:600; color:#ffffff; text-decoration:none; border-radius:10px;")
        end
      end
    end
  end

  # Certains clients avalent les boutons : l'adresse doit rester lisible.
  def mail_button_fallback(url)
    tag.p(style: mail_style(:petit)) do
      safe_join(["Ou copiez ce lien : ", tag.span(url, style: "color:#86868b;")])
    end
  end

  # Paire étiquette / valeur des notifications internes.
  def mail_field(etiquette, valeur)
    safe_join([tag.p(etiquette, style: mail_style(:etiquette)),
               tag.p(valeur.presence || "—", style: mail_style(:valeur))])
  end

  def mail_divider
    tag.div(" ".html_safe, style: "height:1px; background-color:#eeeef2; line-height:1px; font-size:0;")
  end
end
