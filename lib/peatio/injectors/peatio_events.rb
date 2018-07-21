module Peatio::Injectors
  class PeatioEvents
    attr_accessor :market, :seller_uid, :buyer_uid

    def run!
      require "time"
      @market = "btcusd"
      @seller_uid = 21
      @buyer_uid = 42
      @messages = create_messages()

      EventMachine.run do
        AMQP.start(:host => 'localhost') do |connection|
          puts "Connected to RabbitMQ"
          AMQP::Channel.new do |channel, open_ok|
            puts "Channel ##{channel.id} is now open!"
            AMQP::Exchange.new(channel, :direct, "peatio.events.market") do |exchange, declare_ok|
              puts "#{exchange.name} is ready to go. AMQP method: #{declare_ok.inspect}"
              next_message(connection, exchange)
            end
          end
        end
      end
    end

    def next_message(connection, exchange)
      if message = @messages.pop
        event_name, data = message
        serialized_data = JSON.dump(data)
        exchange.publish(serialized_data, routing_key: event_name) do
          puts "event #{event_name} sent with data: #{serialized_data}"
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
      ]
    end

    def order_created
      [
        "market.#{market}.order_created",
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
          created_at:             (Time.now - 600).iso8601
        }
      ]
    end

    def order_canceled
      [
        "market.#{market}.order_canceled",
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
          created_at:              (Time.now - 600).iso8601,
          canceled_at:             Time.now.iso8601
        }
      ]
    end
  end
end
