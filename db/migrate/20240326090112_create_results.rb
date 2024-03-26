class CreateResults < ActiveRecord::Migration[7.0]
  def change
    create_table :results do |t|
      t.references :student, foreign_key: true
      t.references :skill, foreign_key: true
      t.string :kind
      t.string :status

      t.timestamps
    end
    # launch migration

    # itetration sur les students
    Student.all.each do |student|
    #  get of last wps for each skills
      student.derniers_work_planskills_etudiant.each do |key,value| # {skill => [last_work_plan_skill]}
      #  create resulst based on its kind and status
      # binding.pry
        result = Result.create!( student:, skill: key, status: value.status, kind: value.kind)
        puts "Creation du résult pour #{student.first_name} et la compétence: #{key.name} (#{value.kind}/#{value.status})"
      end
    end
  end
end
