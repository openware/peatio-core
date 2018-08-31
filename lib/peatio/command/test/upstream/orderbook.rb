# frozen_string_literal: true

module Peatio::Command::Test::Upstream
  # Class provides command for testing remote orderbook by fetching in realtime
  # from Binance.
  #
  # This command needs following environment variables to be set:
  #
  # * +UPSTREAM_BINANCE_API_KEY+
  # * +UPSTREAM_BINANCE_API_SECRET+
  #
  # @example Display orderbook for tusdbtc every 5 seconds
  #   bin/peatio test upstream orderbook -m tusdbtc
  #
  # @example Display orderbook for tusdbtc and ethbtc every 5 seconds
  #   bin/peatio test upstream orderbook -m tusdbtc -m ethbtc
  class Orderbook < Peatio::Command::Base
    option(
      ["-m", "--market"], "MARKET...",
      "markets to listen",
      multivalued: true,
      required: true,
    )

    option(
      ["--dump-interval"], "INTERVAL",
      "interval in seconds for dumping orderbook",
      default: 5,
    ) { |v| Integer(v) }

    # @!visibility protected
    def execute
      EM.run {
        upstream = ::Peatio::Upstream::Binance.new
        upstream.start!(market_list)
        upstream.on(:open) { |orderbooks|
          logger = Peatio::Logger.logger

          EM::PeriodicTimer.new(dump_interval) do
            orderbooks.each do |symbol, orderbook|
              asks, bids = orderbook.depth(5)

              asks.each do |(price, volume)|
                logger.info "[#{symbol}] {orderbook} ASK #{price} #{volume}"
              end

              bids.each do |(price, volume)|
                logger.info "[#{symbol}] {orderbook} BID #{price} #{volume}"
              end
            end
          end
        }

        upstream.on(:error) {
          EM.stop
        }
      }
    end
  end
end
