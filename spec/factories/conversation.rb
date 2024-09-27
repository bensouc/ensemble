FactoryBot.define do
  factory :conversation do
    conversation_type { %w[ensemble grade school classic].sample }
    name { "Ensemble" }
    users { [create(:user)] }
  end
end
