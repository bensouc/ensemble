# frozen_string_literal: true

FactoryBot.define do
  factory :shared_classroom do
    user
    classroom
  end
end
