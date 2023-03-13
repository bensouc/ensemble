FactoryBot.define do

  factory :classroom do
    user
    # binding.pry
    name {Faker::Name.name }
    grade {%w(CP CE1 CE2 CM1 CM2).sample }
  end
end
