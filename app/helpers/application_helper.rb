module ApplicationHelper
  def random_background
    ["image_bg_1.jpg", "image_bg_2.jpg"].sample
  end

  TUTO_SOMMAIRE = "https://vroadstudio.notion.site/Ensemble-Les-Tutos-1bb72deab51d43898dd2bdcec25ec098".freeze

  # Le bouton d'aide de la barre du haut pointe vers le tuto du sujet affiché.
  # Ces URL sont la seule chose qui relie l'app au Notion : renommer une de ces
  # pages change son slug et casse le lien. Les deux dernières utilisent
  # l'identifiant nu, insensible au renommage — à préférer pour les ajouts.
  TUTO_LINKS = {
    "skills" => "https://vroadstudio.notion.site/G-rer-les-comp-tences-du-groupe-cole-234534e947734471ab36a40e35433943?pvs=4",
    "challenges" => "https://vroadstudio.notion.site/Les-Exercices-39c32f7477a248c2889b93d055df67b8?pvs=4",
    "classrooms" => "https://vroadstudio.notion.site/G-rer-vos-classes-4f58dcf62df44cdca2b48054df551256?pvs=4",
    "work_plans" => "https://vroadstudio.notion.site/Vos-Plans-de-Travail-8eea69c2f9be452e89e528a7e3f56f0d?pvs=4",
    "subscriptions" => "#{TUTO_SOMMAIRE}/S-abonner-9d9b895b3e9042648df01943941dcb07?pvs=4",
    # Ces deux tutos existaient déjà mais n'étaient reliés à aucun écran :
    # depuis les résultats ou la messagerie, le bouton renvoyait au sommaire.
    "results" => "https://vroadstudio.notion.site/3d10c7c8e7ad44f5b1550f35e1d811c0",
    "conversations" => "https://vroadstudio.notion.site/119546308549805ab021f414c4b33d84"
  }.freeze

  def get_tuto_links(controller_name)
    TUTO_LINKS.fetch(controller_name,
                     "#{TUTO_SOMMAIRE}/Ensemble-Les-Tutos-1bb72deab51d43898dd2bdcec25ec098")
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
