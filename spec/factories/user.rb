# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { "123456" }
    first_name { "adminJoe" }
    last_name { "adminSouc" }
    admin { true }
    school
  end
end
