  FactoryBot.define do

  factory :skill do
    domain {["Vocabulaire", "Conjugaison", "Orthographe",
                                       "Grammaire", "Numération", "Calcul", "Poésie", "Géométrie",
                                       "Grandeurs et Mesures", "Opérations", "Résolution des Problèmes",
                                       "Calligraphie", "Poésie et Expression orale",
                                       "Production d’écrit", "Lecture"].sample}
    level {[1, 2, 3, 4, 5, 6, 7].sample}
    grade {%w(CP CE1 CE2 CM1 CM2).sample }
    symbol {["◼", "⬥", "⬟", "♥", "⬤", "♣", "🞮", "▲", ""].sample}
    name {Faker::Lorem.sentence(word_count: 3, supplemental: false, random_words_to_add: 4)}
  end
end
