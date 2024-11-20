# config init Gem LogRage
Rails.application.configure do
  # Enable lograge for logging
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Json.new #render log in json format
  config.lograge.base_controller_class = ['ApplicationController'] #
  config.lograge.custom_payload do |controller|
    {
      remote_ip: controller.request.remote_ip,
      user_id: controller.signed_in? ? controller.current_user.id : "not authenticated"
    }
  end


end
