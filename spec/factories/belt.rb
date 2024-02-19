# frozen_string_literal: true

FactoryBot.define do
  factory :belt do
    student
    domain
    level { (1..7).to_a.sample }
    validated_date { nil }
    completed { false }
  end
end
