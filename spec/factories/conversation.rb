FactoryBot.define do
  factory :conversation do
    conversation_type { "ensemble" }
    name { "Ensemble" }
    users { [create(:user)] }
  end
end
