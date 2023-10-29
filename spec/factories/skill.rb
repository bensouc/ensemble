# frozen_string_literal: true

FactoryBot.define do
  factory :skill do
    domain do
      ["Vocabulaire", "Conjugaison", "Orthographe",
       "Grammaire", "Numération", "Calcul", "Poésie", "Géométrie",
       "Grandeurs et Mesures", "Opérations", "Résolution des Problèmes",
       "Calligraphie", "Poésie et Expression orale",
       "Production d’écrit", "Lecture"].sample
    end
    level { [1, 2, 3, 4, 5, 6, 7].sample }
    grade 
    symbol { ["◼", "⬥", "⬟", "♥", "⬤", "♣", "🞮", "▲", ""].sample }
    name { Faker::Lorem.sentence(word_count: 3, supplemental: false, random_words_to_add: 4) }
    school
  end
end
