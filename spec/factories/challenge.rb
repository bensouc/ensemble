FactoryBot.define do

  factory :challenge do
    user
    skill
    name  {Faker::Lorem.sentence(word_count: 3, supplemental: false, random_words_to_add: 4)}
    content  {Faker::Lorem.paragraph(sentence_count: 2, supplemental: false, random_sentences_to_add: 4)}
  end
end
