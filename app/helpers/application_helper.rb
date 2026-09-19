module ApplicationHelper
  def random_background
    ["image_bg_1.jpg", "image_bg_2.jpg"].sample
  end

  # Ces URL sont la seule chose qui relie l'app au Notion, et elles s'écrivent
  # toutes de la même façon : l'identifiant nu de la page, rien d'autre.
  #
  # Notion propose aussi une forme avec le titre en préfixe
  # (`/G-rer-vos-classes-4f58dcf6…`). Ce préfixe est le titre du moment :
  # renommer la page dans Notion le change, et le lien meurt sans que l'app en
  # sache rien. L'identifiant, lui, ne bouge jamais.
  #
  # Deux de ces URL étaient par ailleurs construites par interpolation à partir
  # du sommaire, ce qui donnait un chemin doublé
  # (`…/Ensemble-Les-Tutos-1bb72dea…/S-abonner-9d9b895b…`). Elles marchaient
  # quand même : Notion redirige sur l'identifiant final. Mieux vaut ne pas
  # dépendre de ce rattrapage.
  NOTION = "https://vroadstudio.notion.site".freeze

  TUTO_SOMMAIRE = "#{NOTION}/1bb72deab51d43898dd2bdcec25ec098".freeze

  # Le bouton d'aide de la barre du haut pointe vers le tuto du sujet affiché.
  TUTO_LINKS = {
    "skills" => "#{NOTION}/234534e947734471ab36a40e35433943",
    "challenges" => "#{NOTION}/39c32f7477a248c2889b93d055df67b8",
    "classrooms" => "#{NOTION}/4f58dcf62df44cdca2b48054df551256",
    "work_plans" => "#{NOTION}/8eea69c2f9be452e89e528a7e3f56f0d",
    "subscriptions" => "#{NOTION}/9d9b895b3e9042648df01943941dcb07",
    # Ces deux tutos existaient déjà mais n'étaient reliés à aucun écran :
    # depuis les résultats ou la messagerie, le bouton renvoyait au sommaire.
    "results" => "#{NOTION}/3d10c7c8e7ad44f5b1550f35e1d811c0",
    "conversations" => "#{NOTION}/119546308549805ab021f414c4b33d84"
  }.freeze

  def get_tuto_links(controller_name)
    TUTO_LINKS.fetch(controller_name, TUTO_SOMMAIRE)
  end

  # Pages destinées à quelqu'un qui n'est pas connecté : le menu de gauche et le
  # bandeau ne lui montreraient que des impasses. L'acceptation d'invitation en
  # fait partie — l'invité arrive de sa boîte mail, sans compte encore ouvert.
  def chrome_free_page?
    return true if %w[devise/registrations devise/sessions devise/passwords].include?(params[:controller])

    params[:controller] == "users/invitations" && %w[edit update].include?(params[:action])
  end

  def cacher_email(email)
    username, domain = email.split("@")
    censored_username = username[0] + "****" + username[0]
    censored_domain = domain.gsub(/(?<=.{1}).(?=.*\.)/, "*")
    "#{censored_username}@#{censored_domain}"
  end

  def self.default_url_options
    { host: ENV["DOMAIN"] || "http://localhost:3000" }
  end

  def sanitize_filename(filename)
    I18n.transliterate(filename).gsub!(/[^0-9A-Za-z]/, "_")
  end
end
