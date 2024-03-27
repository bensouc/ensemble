# frozen_string_literal: true

FactoryBot.define do
  factory(:domain) do
    grade
    position {(1..10).to_a.sample}
    special {[true,false].sample}
    name {["Conjugaison", "Vocabulaire", "Orthographe", "Grammaire", "Poésie", "Géométrie", "Grandeurs et Mesures",
              "Numération", "Calcul"].sample}
  end
end
