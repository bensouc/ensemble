# frozen_string_literal: true

FactoryBot.define do
  factory :student do
    classroom
    first_name { Faker.name }
  end
end
