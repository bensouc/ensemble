class WorkPlanSkill < ApplicationRecord
  belongs_to :work_plan_domain
  belongs_to :skill
  belongs_to :challenge, optional: true
  belongs_to :student, optional: true

  validates :kind, presence: true, inclusion: { in: %w(jeu exercice controle ceinture) }
  validates :status, inclusion: { in: %w(redo failed redo_OK completed new) }

  def clone(current_wp, new_wp_domain)
    new_wps = self.dup
    new_wps.work_plan_domain_id = new_wp_domain.id
    new_wps.student = current_wp.student
    new_wps.status = "new"
    new_wps.save
  end

  def self.last_4_wps(work_plan, wps)
    # retrieve the last 4 wps for the student on this skill ids
    out = WorkPlanSkill.where(student: work_plan.student, skill: wps.skill_id).sort_by(&:created_at).reverse
    out.reject { |t| t == wps }
    out.last(3)
  end

  def self.last_wps(student_id, skill_id)
    WorkPlanSkill.where(skill_id: skill_id, student_id: student_id).last
  end

  # must test all last wps on each skill of its skill domains
  # def test_wps_belt?(mode = 'all')
  #   self.work_plan_domain.all_domain_skills

  #   if mode == 'all'
  #     self.skill_id
  #   else
  #     'repos'
  #   end
  # end

end
