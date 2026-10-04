# frozen_string_literal: true

# La factory :skill fabrique son propre domaine ET sa propre école, qui peuvent
# être deux écoles différentes. On recolle les deux ici, sinon les specs de
# Manipule héritent d'une incohérence qui n'a rien à voir avec elles.
FactoryBot.define do
  factory :manipule_skill, class: "Skill" do
    domain
    school { domain.grade.school }
    level { 1 }
    symbol { "◼" }
    name { "Recherche d'une partie" }
  end

  factory :manipule_problem, class: "Manipule::Problem" do
    association :skill, factory: :manipule_skill
    statement { "Il y a 15 pommes sur le pommier. Sam cueille 7 pommes." }
    question { "Combien reste-t-il de pommes sur le pommier ?" }
    answer_mode { "choix" }
    published { true }

    # Un problème à choix n'est valide qu'avec exactement une bonne réponse :
    # la factory la fournit, sinon rien ne s'enregistre.
    after(:build) do |probleme|
      next if probleme.choices.any? || probleme.saisie?

      probleme.choices.build(label: "8 pommes", correct: true, position: 1)
      probleme.choices.build(label: "22 pommes", correct: false, position: 2)
      probleme.choices.build(label: "7 pommes", correct: false, position: 3)
    end

    trait :saisie do
      answer_mode { "saisie" }
      answer { "8" }
      unit { "pommes" }
    end

    trait :brouillon do
      published { false }
    end
  end

  factory :manipule_assignment, class: "Manipule::Assignment" do
    student
    association :skill, factory: :manipule_skill
    user
  end

  factory :manipule_practice, class: "Manipule::Practice" do
    student
    association :skill, factory: :manipule_skill
    started_at { Time.current }
  end

  factory :manipule_classroom_token, class: "Manipule::ClassroomToken" do
    classroom
  end
end
