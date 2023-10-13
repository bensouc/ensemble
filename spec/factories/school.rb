# frozen_string_literal: true

FactoryBot.define do
  factory :school do
    name { Faker::Name.name }
    city { Faker::Address.city }
    email { Faker::Internet.email }
  end
end
