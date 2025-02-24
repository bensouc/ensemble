# frozen_string_literal: true

FactoryBot.define do
  factory :school_role do
    association :user
    association :school
  end
end
