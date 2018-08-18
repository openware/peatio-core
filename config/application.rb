# encoding: UTF-8
# frozen_string_literal: true

Peatio::Application.configure do |config|

  config.ranger.host  = ENV.fetch('RANGER_HOST', '0.0.0.0')
  config.ranger.port  = ENV.fetch('RANGER_PORT', '8081')

  ## Example middleware
  # config.middleware.use RangerDebug::Middleware
end
