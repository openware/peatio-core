# frozen_string_literal: true

module Peatio::Command::Service
  class Start < Peatio::Command::Base
    class Ranger < Peatio::Command::Base
      def execute
        if ENV["JWT_PUBLIC_KEY"].nil?
          raise ArgumentError, "JWT_PUBLIC_KEY was not specified."
        end

        key_decoded = Base64.urlsafe_decode64(ENV["JWT_PUBLIC_KEY"])

        jwt_public_key = OpenSSL::PKey.read(key_decoded)
        if jwt_public_key.private?
          raise ArgumentError, "JWT_PUBLIC_KEY was set to private key, however it should be public."
        end

        ::Peatio::Ranger.run!(jwt_public_key)
      end
    end

    class UpstreamBinance < Peatio::Command::Base
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

      def execute
        EM.run {
          orderbooks, trader = ::Peatio::Upstream::Binance.run!(
            markets: market_list,
          )

          logger = Peatio::Upstream::Binance.logger

          order = trader.order(
            timeout: 10,
            symbol: "TUSDBTC",
            type: "LIMIT",
            side: "BUY",
            quantity: 10.0,
            price: 0.000145,
          )

          order.on :error do |request|
            puts request.response
            puts request.response_header.status
          end

          order.on :submit do |id|
            logger.info "XXX order submitted: #{id}"
          end

          order.on :partially_filled do |quantity, price|
            logger.info "XXX order partially filled: #{quantity} #{price}"
          end

          order.on :filled do |quantity, price|
            logger.info "XXX order filled: #{quantity} #{price}"
          end

          order.on :cancelled do
            logger.info "XXX order cancelled: #{order.quantity} left"
          end

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
      end
    end

    subcommand "ranger", "Start ranger process", Ranger
    subcommand "upstream", "Start upstream binance process", UpstreamBinance
  end

  class Root < Peatio::Command::Base
    subcommand "start", "Start a service", Start
  end
end
