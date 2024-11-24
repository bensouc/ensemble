# frozen_string_literal: true

FactoryBot.define do
  factory :skill do
    domain
    level {domain.special? ? 1 : [1, 2, 3, 4, 5, 6, 7].sample }
    symbol { ["◼", "⬥", "⬟", "♥", "⬤", "♣", "🞮", "▲", ""].sample }
    name { Faker::Lorem.sentence(word_count: 3, supplemental: false, random_words_to_add: 4) }
    school
  end
end
