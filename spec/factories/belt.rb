# frozen_string_literal: true

FactoryBot.define do
  factory :belt do
    student
    domain { WorkPlanDomain::DOMAINS["CM1"].sample }
    level { (1..7).to_a.sample }
    grade {"CM1"}
    validated_date { nil }
    completed { false }
  end
end
