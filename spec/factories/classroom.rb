# frozen_string_literal: true

FactoryBot.define do
  factory :classroom do
    user
    name { Faker::Name.name }
    grade 
  end
end
