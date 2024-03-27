# frozen_string_literal: true

FactoryBot.define do
  factory :work_plan_domain do
    domain 
    level { [1, 2, 3, 4, 5, 6, 7].sample }
    work_plan
  end
end
