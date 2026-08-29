require "rails_helper"

RSpec.describe SchoolRole, type: :model do
  before do
    @school_role = create(:school_role)
  end

  it " is valid with valid attributes" do
    expect(@school_role).to be_valid
  end
end
