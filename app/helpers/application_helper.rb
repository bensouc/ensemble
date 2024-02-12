module ApplicationHelper
    def random_background
        ["image_bg_1.jpg", "image_bg_2.jpg"].sample
    end

    def get_tuto_links(controller_name)
      case controller_name
      when 'skills'
        'https://www.notion.so/G-rer-les-comp-tences-du-groupe-cole-234534e947734471ab36a40e35433943?pvs=4'
      when 'challenges'
        'https://www.notion.so/Les-Exercices-39c32f7477a248c2889b93d055df67b8?pvs=4'
      when 'classrooms'
        'https://www.notion.so/G-rer-vos-classes-4f58dcf62df44cdca2b48054df551256?pvs=4'
      when 'work_plans'
        'https://www.notion.so/Vos-Plans-de-Travail-8eea69c2f9be452e89e528a7e3f56f0d?pvs=4'
      else
        'https://season-sycamore-125.notion.site/Ensemble-Les-Tutos-1bb72deab51d43898dd2bdcec25ec098'
      end
    end

    def cacher_email(email)
  parts = email.split('@')
  username = parts[0]
  domain = parts[1]

  # Cacher le nom d'utilisateur
  if username.length > 2
    censored_username = username[0] + '*' * (username.length - 2) + username[-1]
  else
    censored_username = username
  end

  # Cacher le domaine
  domain_parts = domain.split('.')
  if domain_parts.length > 2
    censored_domain = domain_parts[0] + '*' * (domain_parts[-2].length - 2) + domain_parts[-1]
  else
    censored_domain = domain
  end

  "#{censored_username}@#{censored_domain}"
end

end
