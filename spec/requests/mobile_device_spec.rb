# frozen_string_literal: true

require "rails_helper"

# app/controllers/concerns/mobile_device.rb remplace la gem `mobile` : la
# détection doit rester la même, sans quoi la mise en page servie change.
RSpec.describe "Détection des appareils mobiles" do
  user_agents = {
    "iPhone" => "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 " \
                "(KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1",
    "iPad" => "Mozilla/5.0 (iPad; CPU OS 16_6 like Mac OS X) AppleWebKit/605.1.15 " \
              "(KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1",
    "Android" => "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 " \
                 "(KHTML, like Gecko) Chrome/126.0 Mobile Safari/537.36",
    "Chrome sur Mac" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 " \
                        "(KHTML, like Gecko) Chrome/126.0 Safari/537.36",
    "Firefox sur Windows" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:128.0) Gecko/20100101 Firefox/128.0"
  }

  it "reconnaît téléphones et tablettes, et eux seuls" do
    verdicts = user_agents.transform_values { |ua| MobileDevice::USER_AGENTS.match?(ua.downcase) }

    expect(verdicts).to eq("iPhone" => true, "iPad" => true, "Android" => true,
                           "Chrome sur Mac" => false, "Firefox sur Windows" => false)
  end

  # Le helper sert dans le layout et la page d'accueil : il doit y être joignable.
  it "sert la page d'accueil sur mobile comme sur ordinateur", type: :request do
    get root_path, headers: { "User-Agent" => user_agents["iPhone"] }
    expect(response).to have_http_status(:ok)

    get root_path, headers: { "User-Agent" => user_agents["Chrome sur Mac"] }
    expect(response).to have_http_status(:ok)
  end
end
