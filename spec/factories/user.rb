 FactoryBot.define do
   factory :user do
    email {"#{Faker::Name}@gmail.com"}
    password {"123456"}
    first_name {"adminJoe"}
    last_name {"adminSouc"}
    admin {true}
    school
  end
end
