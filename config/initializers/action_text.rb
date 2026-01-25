# Rails 7.1+ configuration for Action Text
Rails.application.config.after_initialize do
  # Allow style attribute for custom styling in rich text
  ActionText::ContentHelper.allowed_attributes = Set.new(
    Loofah::HTML5::SafeList::ALLOWED_ATTRIBUTES + %w[style]
  )
end
