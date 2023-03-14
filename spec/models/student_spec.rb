# frozen_string_literal: true

require "rails_helper"
RSpec.describe Student, type: :model do
  before(:all) do
    Challenge.destroy_all
    User.destroy_all
    @student1 = create(:student)
  end

  it "is valid with valid attributes" do
    expect(@student1).to be_valid
    # p @skill1
  end
end
