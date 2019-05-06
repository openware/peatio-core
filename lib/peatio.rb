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
  require_relative "peatio/security/key_generator"
  require_relative "peatio/auth/jwt_authenticator"

  require_relative "peatio/blockchain/abstract"
  require_relative "peatio/blockchain/error"
  require_relative "peatio/blockchain/registry"

  require_relative "peatio/wallet/abstract"
  require_relative "peatio/wallet/error"
  require_relative "peatio/wallet/registry"

  require_relative "peatio/transaction"
  require_relative "peatio/block"
end
