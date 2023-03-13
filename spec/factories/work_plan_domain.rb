FactoryBot.define do
  factory :work_plan_domain do
    domain {
      ["Vocabulaire", "Conjugaison", "Orthographe",
       "Grammaire", "Numération", "Calcul", "Poésie", "Géométrie",
       "Grandeurs et Mesures", "Opérations", "Résolution des Problèmes",
       "Calligraphie", "Poésie et Expression orale",
       "Production d’écrit", "Lecture"].sample
    }
    level { [1, 2, 3, 4, 5, 6, 7].sample }
    work_plan
  end
end
