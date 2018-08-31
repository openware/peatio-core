# frozen_string_literal: true

# Module provides commands that can be used to run upstream test tools from
# CLI.
#
# @example
#   bin/peatio test upstream [...]
# @see Orderbook
# @see Order
module Peatio::Command::Test::Upstream
  require_relative "upstream/orderbook"
  require_relative "upstream/order"

  # @!visibility protected
  class Root < Peatio::Command::Base
    subcommand "orderbook", "Start remote orderbook listener", Orderbook
    subcommand "order", "Place real order into remote upstream", Order
  end
end
