# Rails 7.1+ configuration for Action Text
Rails.application.config.after_initialize do
  # Allow style attribute and data attributes for custom styling and table editors
  ActionText::ContentHelper.allowed_attributes = Set.new(
    Loofah::HTML5::SafeList::ALLOWED_ATTRIBUTES + %w[
      style value id data-key contenteditable
    ]
  )

  # Allow table elements and form elements for table attachments
  ActionText::ContentHelper.allowed_tags = Set.new(
    Loofah::HTML5::SafeList::ALLOWED_ELEMENTS + %w[
      table thead tbody tfoot tr th td colgroup col
      input button strong em b i
    ]
  )
end
