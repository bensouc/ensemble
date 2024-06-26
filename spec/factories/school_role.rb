# frozen_string_literal: true

FactoryBot.define do
  factory :school_role do
    user { User.first}
    school { School.first }
  end
end
