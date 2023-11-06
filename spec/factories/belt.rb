# frozen_string_literal: true

FactoryBot.define do
  factory :belt do
    student
    domain { ["Vocabulaire", "Conjugaison", "Orthographe",
       "Grammaire", "Numération", "Calcul", "Poésie", "Géométrie",
       "Grandeurs et Mesures", "Opérations", "Résolution des Problèmes",
       "Calligraphie", "Poésie et Expression orale",
       "Production d’écrit", "Lecture"].sample }
    level { (1..7).to_a.sample }
    grade {Grade.all.sample}
    validated_date { nil }
    completed { false }
  end
end
