# encoding: UTF-8
# frozen_string_literal: true

Peatio::Application.configure do |config|
  config.log_level  = ENV.fetch('LOG_LEVEL', 'INFO')
end
