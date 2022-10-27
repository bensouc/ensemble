require "rails_helper"

RSpec.describe "Workplans", type: :system do
  before do
    driven_by(:rack_test)
    Rails.application.load_seed
    login_as(User.first)
  end

  it "load the Workplan index for a user" do
    wp = WorkPlan.last
    # p wp
    visit work_plan_path(wp.id)
    expect(page).to have_content(wp.name)
  end
end
