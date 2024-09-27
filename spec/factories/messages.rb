FactoryBot.define do
  factory :message do
    content { "This is a test message" }
    read { false }
    association :user
    association :conversation
  end
end
