# frozen_string_literal: true

class DomainsController < ApplicationController
   skip_after_action :verify_policy_scoped, only: [:index]

   def index
    @grade = Grade.find(params[:grade_id])
    @domains = @grade.domains
  end
end
