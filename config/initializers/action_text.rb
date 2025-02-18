Rails.application.config.after_initialize do
# Autoriser les balises HTML spécifiques
  ActionText::ContentHelper.allowed_tags = [
    'div', 'strong', 'br', 'span', 'h1', 'h2', 'h3', 'p', 'ul', 'ol', 'li',
    'blockquote', 'pre', 'code', 'i', 'b', 'em'
  ]

  # Autoriser les attributs HTML spécifiques
  ActionText::ContentHelper.allowed_attributes = [
    'class', 'style', 'href', 'title', 'target', 'rel', 'data-*'
  ]

  # Autoriser les styles CSS spécifiques
  ActionText::ContentHelper.scrubber = Loofah::Scrubber.new do |node|
    if node.name == 'span' && node['style']
      allowed_styles = ['color', 'background-color', 'font-weight']
      styles = node['style'].split(';').select do |style|
        style_name = style.split(':').first&.strip
        allowed_styles.include?(style_name)
      end
      node['style'] = styles.join(';')
    end
  end
end
