# frozen_string_literal: true

# La colonne `code` a été ajoutée en mars 2024 puis laissée vide : rien ne l'a
# jamais écrite. On la remplit pour toutes les écoles, on normalise en majuscules
# les rares codes saisis à la main, puis on pose l'index unique qui manquait.
#
# Le modèle n'est pas utilisé ici : ses validations exigent désormais un code, ce
# que les lignes qu'on vient précisément réparer n'ont pas encore.
class BackfillAndIndexSchoolCodes < ActiveRecord::Migration[7.1]
  ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"
  LENGTH = 6

  class MigrationSchool < ActiveRecord::Base
    self.table_name = "schools"
  end

  def up
    taken = Set.new

    MigrationSchool.order(:id).each do |school|
      code = school.code.to_s.strip.upcase
      # Vide, ou déjà pris par une autre école (deux saisies à la main qui ne
      # différaient que par la casse) : on en tire un neuf.
      code = draw(taken) if code.empty? || taken.include?(code)
      taken << code
      school.update_column(:code, code) unless code == school.code
    end

    add_index :schools, :code, unique: true
  end

  def down
    remove_index :schools, :code
  end

  private

  def draw(taken)
    loop do
      candidate = Array.new(LENGTH) { ALPHABET.chars.sample }.join
      return candidate unless taken.include?(candidate)
    end
  end
end
