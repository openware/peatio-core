module Peatio::Injectors
  class PeatioEvents
    attr_accessor :market, :seller_uid, :buyer_uid, :logger

    def run!
      require "time"
      @logger = Peatio::Logger.logger
      @market = "eurusd"
      @seller_uid = 21
      @buyer_uid = 42
      @messages = create_messages
      @exchange_name = "peatio.events.market"

      EventMachine.run do
        AMQP.start(host: "localhost") do |connection|
          logger.info "Connected to RabbitMQ"
          AMQP::Channel.new do |channel, open_ok|
            logger.info "Channel ##{channel.id} is now open!"
            AMQP::Exchange.new(channel, :direct, @exchange_name) do |exchange, declare_ok|
              logger.info "Exchange #{exchange.name} is ready to go"
              next_message(connection, exchange)
            end
          end
        end
      end
    end

    def next_message(connection, exchange)
      if message = @messages.shift
        event_name, data = message
        serialized_data = JSON.dump(data)
        exchange.publish(serialized_data, routing_key: event_name) do
          logger.debug { "event #{event_name} sent with data: #{serialized_data}" }
          next_message(connection, exchange)
        end
      else
        connection.close { EventMachine.stop }
      end
    end

    def create_messages
      [
        order_created,
        order_canceled,
        order_completed,
        order_updated,
        trade_completed,
      ]
    end

    def created_at
      Time.now - 600
    end

    def updated_at
      Time.now
    end
    alias :completed_at :updated_at
    alias :canceled_at  :updated_at

    def order_created
      [
        "#{market}.order_created",
        {
          market:                 "#{market}",
          type:                   "buy",
          trader_uid:             buyer_uid,
          income_unit:            "btc",
          income_fee_type:        "relative",
          income_fee_value:       "0.0015",
          outcome_unit:           "usd",
          outcome_fee_type:       "relative",
          outcome_fee_value:      "0.0",
          initial_income_amount:  "14.0",
          current_income_amount:  "14.0",
          initial_outcome_amount: "0.42",
          current_outcome_amount: "0.42",
          strategy:               "limit",
          price:                  "0.03",
          state:                  "open",
          trades_count:           0,
          created_at:             created_at.iso8601
        }
      ]
    end

    def order_canceled
      [
        "#{market}.order_canceled",
        {
          market:                  "#{market}",
          type:                    "sell",
          trader_uid:              seller_uid,
          income_unit:             "usd",
          income_fee_type:         "relative",
          income_fee_value:        "0.0015",
          outcome_unit:            "btc",
          outcome_fee_type:        "relative",
          outcome_fee_value:       "0.0",
          initial_income_amount:   "3.0",
          current_income_amount:   "3.0",
          initial_outcome_amount:  "100.0",
          current_outcome_amount:  "100.0",
          strategy:                "limit",
          price:                   "0.03",
          state:                   "canceled",
          trades_count:            0,
          created_at:              created_at.iso8601,
          canceled_at:             canceled_at.iso8601
        }
      ]
    end

    def order_completed
      [
        "#{market}.order_completed", {
          market:                  "#{market}",
          type:                    "sell",
          trader_uid:              seller_uid,
          income_unit:             "usd",
          income_fee_type:         "relative",
          income_fee_value:        "0.0015",
          outcome_unit:            "btc",
          outcome_fee_type:        "relative",
          outcome_fee_value:       "0.0",
          initial_income_amount:   "3.0",
          current_income_amount:   "0.0",
          previous_income_amount:  "3.0",
          initial_outcome_amount:  "100.0",
          current_outcome_amount:  "0.0",
          previous_outcome_amount: "100.0",
          strategy:                "limit",
          price:                   "0.03",
          state:                   "completed",
          trades_count:            1,
          created_at:              created_at.iso8601,
          completed_at:            completed_at.iso8601
        }
      ]
    end

    def order_updated
      [
        "#{market}.order_updated", {
          market:                  "#{market}",
          type:                    "sell",
          trader_uid:              seller_uid,
          income_unit:             "usd",
          income_fee_type:         "relative",
          income_fee_value:        "0.0015",
          outcome_unit:            "btc",
          outcome_fee_type:        "relative",
          outcome_fee_value:       "0.0",
          initial_income_amount:   "3.0",
          current_income_amount:   "2.4",
          previous_income_amount:  "3.0",
          initial_outcome_amount:  "100.0",
          current_outcome_amount:  "80.0",
          previous_outcome_amount: "100.0",
          strategy:                "limit",
          price:                   "0.03",
          state:                   "open",
          trades_count:            1,
          created_at:              created_at.iso8601,
          updated_at:              updated_at.iso8601
        }
      ]
    end

    def trade_completed
      [
        "#{market}.trade_completed", {
          market:                "#{market}",
          price:                 "0.03",
          buyer_uid:             buyer_uid,
          buyer_income_unit:     "btc",
          buyer_income_amount:   "14.0",
          buyer_income_fee:      "0.021",
          buyer_outcome_unit:    "usd",
          buyer_outcome_amount:  "0.42",
          buyer_outcome_fee:     "0.0",
          seller_uid:            seller_uid,
          seller_income_unit:    "usd",
          seller_income_amount:  "0.42",
          seller_income_fee:     "0.00063",
          seller_outcome_unit:   "btc",
          seller_outcome_amount: "14.0",
          seller_outcome_fee:    "0.0",
          completed_at:          completed_at.iso8601
        }
      ]
    end

  end
end
