# frozen_string_literal: true

FactoryBot.define do
  factory :work_plan do
    user
    grade 
    name { Faker::Lorem.word }
    start_date { Faker::Date.forward(days: 23) }
    end_date { start_date + 5 }
  end
end
