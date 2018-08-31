# frozen_string_literal: true

module Peatio::Command::Test::Upstream
  # Class provides command for testing order execution in Binance from CLI.
  #
  # This command needs following environment variables to be set:
  #
  # * +UPSTREAM_BINANCE_API_KEY+
  # * +UPSTREAM_BINANCE_API_SECRET+
  #
  # @example Buy 10.0 TUSD for 0.00014305 BTC with 5 second timeout
  #   bin/peatio test upstream order -m tusdbtc -t limit -s buy -q 10 -p 0.00014305 -w 5
  #
  # @example Same as above, but place IOC (Immediate or Cancel) order.
  #   bin/peatio test upstream order -m tusdbtc -t limit -s buy -q 10 -p 0.00014305 -w 0
  class Order < Peatio::Command::Base
    option(
      ["-m", "--market"], "MARKET",
      "markets to submit order",
      required: true,
    )

    option(
      ["-w", "--timeout"], "TIMEOUT",
      "timeout for order fulfilment",
      default: 5,
    ) { |v| Integer(v) }

    option(
      ["-t", "--type"], "TYPE",
      "order kind: limit or market",
    )

    option(
      ["-s", "--side"], "SIDE",
      "order side: buy or sell",
    )

    option(
      ["-q", "--quantity"], "QUANTITY",
      "quantity to put in order",
    ) { |v| Float(v) }

    option(
      ["-p", "--price"], "PRICE",
      "price to put in order",
    ) { |v| Float(v) }

    # @!visibility protected
    def execute
      EM.run {
        binance = Peatio::Upstream::Binance.new

        order = binance.trader.order(
          timeout: timeout,
          symbol: market.upcase,
          type: type.upcase,
          side: side.upcase,
          quantity: quantity,
          price: price,
        )

        order.on :error do |request|
          puts("> order error: #{request.response}")
          EM.stop
        end

        order.on :submitted do |id|
          puts("> order submitted: #{id}")
        end

        order.on :partially_filled do |quantity, price|
          puts("> order partially filled: #{quantity} #{price}")
        end

        order.on :filled do |quantity, price|
          puts("> order filled: #{quantity} #{price}")
          EM.stop
        end

        order.on :canceled do
          puts("> order canceled: #{order.quantity} left")
          EM.stop
        end
      }
    end
  end
end
