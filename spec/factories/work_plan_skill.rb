# frozen_string_literal: true

FactoryBot.define do
  factory :work_plan_skill do
    work_plan_domain
    skill
    kind { "ceinture" }
  end
end
