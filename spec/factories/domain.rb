# frozen_string_literal: true

FactoryBot.define do
  factory(:domain) do
    grade
    position {(1..10).to_a.sample}
    name {["Conjugaison", "Vocabulaire", "Orthographe", "Grammaire", "Poésie", "Géométrie", "Grandeurs et Mesures",
              "Numération", "Calcul"].sample}
    special {( ["Géométrie", "Grandeurs et Mesures"].include?(name) && ["CE1", "CE2","CM1"].include?(grade.grade_level)) ? true : false }
  end
end
