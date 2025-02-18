# frozen_string_literal: true



class Table < ApplicationRecord
  include GlobalID::Identification
  include ActionText::Attachable

  def to_trix_content_attachment_partial_path
    "tables/editor"
  end

  def clone
    clone_table = dup
    clone_table.save!
    clone_table
  end
end
