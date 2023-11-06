# frozen_string_literal: true

FactoryBot.define do
  factory :grade do
    name { %w[CP CE1 CE2 CM1 CM2].sample }
    grade_level { %w[CP CE1 CE2 CM1 CM2].sample }
    school
  end
end
