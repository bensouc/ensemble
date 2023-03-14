# frozen_string_literal: true

FactoryBot.define do
  factory :classroom do
    user
    name { Faker::Name.name }
    grade { %w[CP CE1 CE2 CM1 CM2].sample }
  end
end
