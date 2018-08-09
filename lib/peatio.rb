# frozen_string_literal: true

require "logger"
require "json"
require "mysql2"
require "bunny"
require "eventmachine"
require "em-websocket"

module Peatio
  require_relative "peatio/error"
  require_relative "peatio/logger"
  require_relative "peatio/version"
  require_relative "peatio/sql/client"
  require_relative "peatio/sql/schema"
  require_relative "peatio/mq/client"
  require_relative "peatio/mq/events"
  require_relative "peatio/ranger"
  require_relative "peatio/injectors/peatio_events"
  require_relative "peatio/auth/jwt_authenticator"
  require_relative "peatio/upstream"
  require_relative "peatio/upstream/binance"
end
