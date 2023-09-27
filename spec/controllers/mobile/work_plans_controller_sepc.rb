require "rails_helper"
RSpec.describe WorkPlansController, type: :controller do
  let(:user) { create(:user) }
  let(:work_plan) { create(:work_plan, user:) }
  let(:classroom) { create(:classroom, user:) }
  let(:valid_params) { { work_plan_id: work_plan.id } }

  describe "#index" do
    context "when user is not signed in" do
      it "returns a failure response" do
        get :index
        expect(response).not_to be_successful
      end
      context "when user is signed" do
        it "returns a successful response with a mobile user agent" do
          sign_in(user)
          get :index
          expect(response).to be_successful
        end
        it "redirect to work_plan index for mobile with a mobile user agent" do
          sign_in(user)
          request.env["HTTP_USER_AGENT"] = "Mozilla/5.0 (iPhone; CPU iPhone OS 12_0 like Mac OS X) AppleWebKit/604.1.34 (KHTML, like Gecko) Version/12.0 Mobile/15A5341f Safari/604.1"
          get :index
          expect(response).to render_template("work_plans/index")
        end
      end
    end
  end



  describe "#evaluation" do
    context "when user is not signed in" do
      it "returns a failure response" do
        get :evaluation, params: { id: work_plan.id }
        expect(response).not_to be_successful
      end
    end
    context "when user is signed" do
      it "returns a successful response" do
        sign_in(user)
        get :evaluation, params: { id: work_plan.id }
        expect(response).to be_successful
      end
      it "redirect to work_planevluationfor mobile" do
        sign_in(user)
        get :evaluation, params: { id: work_plan.id }
        expect(response).to render_template("work_plans/evaluation")
      end
    end
  end
end
