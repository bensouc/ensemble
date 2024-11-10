# frozen_string_literal: true

FactoryBot.define do
  factory :result do
    skill
    student
    status { ["completed","new","to_redo"].sample }
  end
end
