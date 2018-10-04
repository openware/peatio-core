# frozen_string_literal: true

module Peatio::Command::Test::Upstream
  # Class provides command for testing order execution in Binance from CLI.
  #
  # This command needs following environment variables to be set:
  #
  # * +UPSTREAM_BINANCE_API_KEY+
  # * +UPSTREAM_BINANCE_API_SECRET+
  #
  # @example Cancel order with id 123 on market TUSD
  #   bin/peatio test upstream cancel_order -m tusdbtc -i 123
  class CancelOrder < Peatio::Command::Base
    option(
      ["-m", "--market"], "MARKET",
      "markets to submit order",
      required: true,
    )

    option(
      ["-i", "--id"], "ID",
      "order id",
    ) { |v| Integer(v) }

    # @!visibility protected
    def execute
      EM.run {
        binance = Peatio::Upstream::Binance.new

        order = binance.trader.cancel_order(
          symbol: market.upcase,
          id: id,
        )

        order.on :error do |request|
          puts("> order error: #{request.response}")
          EM.stop
        end

        order.on :canceled do
          puts("> order canceled")
          EM.stop
        end
      }
    end
  end
end
