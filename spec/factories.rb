# app/spec/factories.rb
FactoryBot.define do

  # Define a school

  factory :school do
    name {"nom ecole_test"}
    city {"Ville test"}
  end


  factory :user do
    email {"admin@gmail.com"}
    password {"123456"}
    first_name {"adminJoe"}
    last_name {"adminSouc"}
    admin {true}
    school
  end

end
