module ApplicationHelper
  def random_background
    ["image_bg_1.jpg", "image_bg_2.jpg"].sample
  end

  def get_tuto_links(controller_name)
    case controller_name
    when "skills"
      "https://vroadstudio.notion.site/G-rer-les-comp-tences-du-groupe-cole-234534e947734471ab36a40e35433943?pvs=4"
    when "challenges"
      "https://vroadstudio.notion.site/Les-Exercices-39c32f7477a248c2889b93d055df67b8?pvs=4"
    when "classrooms"
      "https://vroadstudio.notion.site/G-rer-vos-classes-4f58dcf62df44cdca2b48054df551256?pvs=4"
    when "work_plans"
      "https://vroadstudio.notion.site/Vos-Plans-de-Travail-8eea69c2f9be452e89e528a7e3f56f0d?pvs=4"

    when "subscriptions"
      "https://vroadstudio.notion.site/Ensemble-Les-Tutos-1bb72deab51d43898dd2bdcec25ec098/S-abonner-9d9b895b3e9042648df01943941dcb07?pvs=4"
    else
      "https://vroadstudio.notion.site/Ensemble-Les-Tutos-1bb72deab51d43898dd2bdcec25ec098/Ensemble-Les-Tutos-1bb72deab51d43898dd2bdcec25ec098"
    end
  end

  def cacher_email(email)
      username, domain = email.split("@")
      censored_username = username[0]+"****"+username[0]
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
