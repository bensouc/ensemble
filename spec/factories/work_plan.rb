FactoryBot.define do
  factory :work_plan do
    user
    grade { %w(CP CE1 CE2 CM1 CM2).sample }
    name { Faker::Lorem.word }
    start_date { Faker::Date.forward(days: 23) }
    end_date { start_date + 5 }
  end
end
