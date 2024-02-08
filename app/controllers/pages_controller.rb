# frozen_string_literal: true

class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home]

  def home
    @is_chrome = Browser.new(request.user_agent).chrome?
  end
end
