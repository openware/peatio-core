# frozen_string_literal: true

module Peatio
  module Upstream
    class Base
      DEFAULT_DELAY = 1
      WEBSOCKET_CONNECTION_RETRY_DELAY = 2

      attr_accessor :logger

      def initialize(config)
        @host = config["rest"]
        @adapter = config[:faraday_adapter] || :em_synchrony
        @config = config
        @ws_status = false
        @market = config['source']
        @target = config['target']
        @public_trades_cb = []
        @logger = Peatio::Logger.logger
        @peatio_mq = config['amqp']
        mount
      end

      def mount
        @public_trades_cb << method(:on_trade)
      end

      def ws_connect
        logger.info { "Websocket connecting to #{@ws_url}" }
        raise "websocket url missing for account #{id}" unless @ws_url

        @ws = Faye::WebSocket::Client.new(@ws_url)

        @ws.on(:open) do |_e|
          subscribe_trades(@target, @ws)
          subscribe_orderbook(@target, @ws)
          logger.info { "Websocket connected" }
        end

        @ws.on(:message) do |msg|
          ws_read_message(msg)
        end

        @ws.on(:close) do |e|
          @ws = nil
          @ws_status = false
          logger.error "Websocket disconnected: #{e.code} Reason: #{e.reason}"
          Fiber.new do
            EM::Synchrony.sleep(WEBSOCKET_CONNECTION_RETRY_DELAY)
            ws_connect
          end.resume
        end
      end

      def ws_connect_public
        ws_connect
      end

      def subscribe_trades(_market, _ws)
        method_not_implemented
      end

      def subscribe_orderbook(_market, _ws)
        method_not_implemented
      end

      def ws_read_public_message(msg)
        logger.info { "received public message: #{msg}" }
      end

      def ws_read_message(msg)
        logger.debug {"received websocket message: #{msg.data}" }

        object = JSON.parse(msg.data)
        ws_read_public_message(object)
      end

      def on_trade(trade)
        logger.info { "Publishing trade event: #{trade.inspect}" }
        @peatio_mq.enqueue_event("public", @market, "trades", {trades: [trade]})
        @peatio_mq.publish :trade, trade_json(trade), {
          headers: {
            type:     :upstream,
            market:   @market,
          }
        }
      end

      def trade_json(trade)
        trade.deep_symbolize_keys!
        {
          id: trade[:tid],
          price: trade[:price],
          amount: trade[:amount],
          market_id: @market,
          created_at: Time.at(trade[:date]).utc.iso8601,
          taker_type: trade[:taker_type]
        }
      end

      def notify_public_trade(trade)
        @public_trades_cb.each {|cb| cb&.call(trade) }
      end

      def to_s
        "Exchange::#{self.class} config: #{@opts}"
      end

      def build_error(response)
        JSON.parse(response.body)
      rescue StandardError => e
        "Code: #{response.env.status} Message: #{response.env.reason_phrase}"
      end
    end
  end
end
