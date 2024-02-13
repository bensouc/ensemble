class AddDomainToBelt < ActiveRecord::Migration[7.0]
  def change
    rename_column :belts, :domain, :name_domain
    add_reference :belts, :domain, foreign_key: true
    remove_reference :belts, :grade, index: true, foreign_key:true
    remove_reference :skills, :grade, index: true, foreign_key:true

    # update all Belt with new omain
 # update all WPD
    belts = Belt.all
    # iterate on each skill
    belts.each do |belt|
      # get the right domain
      p belt.grade_id
      p belt.name_domain
      new_domain = Domain.find_by(grade_id: belt.grade_id, name: belt.name_domain)

      # link it to the skill via update
       belt.update(domain: new_domain)
       p belt
    end
  end
end
