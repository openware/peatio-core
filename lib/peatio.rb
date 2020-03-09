# frozen_string_literal: true

require "logger"
require "json"
require "base64"
require "mysql2"
require "bunny"
require "eventmachine"
require "em-websocket"
require "socket"
require "securerandom"
require "rack"
require "prometheus/client"
require "prometheus/client/push"
require "prometheus/client/data_stores/single_threaded"
require "prometheus/middleware/exporter"

module Peatio
  require_relative "peatio/error"
  require_relative "peatio/logger"
  require_relative "peatio/version"
  require_relative "peatio/sql/client"
  require_relative "peatio/sql/schema"
  require_relative "peatio/mq/client"
  require_relative "peatio/metrics/server"
  require_relative "peatio/ranger/events"
  require_relative "peatio/ranger/router"
  require_relative "peatio/ranger/connection"
  require_relative "peatio/ranger/web_socket"
  require_relative "peatio/injectors/peatio_events"
  require_relative "peatio/security/key_generator"
  require_relative "peatio/auth/jwt_authenticator"

  require_relative "peatio/blockchain/abstract"
  require_relative "peatio/blockchain/error"
  require_relative "peatio/blockchain/registry"

  require_relative "peatio/wallet/abstract"
  require_relative "peatio/wallet/error"
  require_relative "peatio/wallet/registry"

  require_relative "peatio/upstream/base"
  require_relative "peatio/upstream/registry"

  require_relative "peatio/transaction"
  require_relative "peatio/block"
end
