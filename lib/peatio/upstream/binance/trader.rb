module Peatio::Upstream::Binance
  class Trader < Peatio::Wire
    class Order < Peatio::Wire
      attr_accessor :cancel_timer
      attr_accessor :symbol, :type, :side, :quantity, :price

      def initialize(symbol, type, side, quantity, price)
        @symbol = symbol
        @type = type
        @side = side
        @quantity = quantity
        @price = price
      end
    end

    def logger
      Peatio::Upstream::Binance.logger
    end

    def initialize(client)
      @client = client
      @ready = false
      @open_orders = {}
    end

    def order(timeout:, symbol:, type:, side:, quantity:, price:)
      order = Order.new(symbol, type, side, quantity, price)

      @client.connect_private_streams! {
        @client.private_stream.on :error do |message|
          logger.error "error while listening for private stream: #{message}"
        end

        @client.private_stream.on :open do |event|
          submit_order(timeout, order, @client.private_stream)
        end

        @client.private_stream.on :message do |message|
          payload = JSON.parse(message.data)
          event = payload["e"]

          case event
          when "executionReport"
            process_execution_report(payload, @client.private_stream)
          end
        end
      }

      order
    end

    private

    def submit_order(timeout, order, stream)
      logger.info "[#{order.symbol.downcase}] submitting new order: " \
                  "#{order.type} #{order.side} " \
                  "amount=#{order.quantity} price=#{order.price}"

      request = @client.submit_order(
        symbol: order.symbol,
        side: order.side,
        type: order.type,
        quantity: order.quantity,
        price: order.price,
      )

      request.errback {
        order.emit(:error, request)
      }

      request.callback {
        if request.response_header.status >= 300
          order.emit(:error, request)
        else
          payload = JSON.parse(request.response)

          id = payload["orderId"]

          logger.info "[#{order.symbol.downcase}] ##{id} order submitted: " \
                      "#{order.type} #{order.side} " \
                      "amount=#{order.quantity} price=#{order.price}"

          order.emit(:submit, id)

          @open_orders[id] = order

          order.cancel_timer = EM::add_timer(timeout) {
            logger.info "[#{order.symbol.downcase}] ##{id} cancelling order: " \
                        "timeout expired: #{timeout} seconds"

            request = @client.cancel_order(symbol: order.symbol, id: id)

            request.errback {
              order.emit(:error, request)
              stream.close
            }

            request.callback {
              @open_orders.delete(id)
              order.emit(:cancel)
            }
          }
        end
      }
    end

    def process_execution_report(data, stream)
      symbol = data["s"]
      id = data["i"]
      event, order_status = data["x"], data["X"]
      price = data["L"]

      quantity_filled, quantity_total = data["z"], data["q"]

      if id < 0
        log.error "[#{symbol}] order execution error: event=#{event}"
        return
      end

      logger.debug "[#{symbol.upcase}] ##{id} order execution report: " \
                   "event=#{event} order_status=#{order_status} " \
                   "quantity=#{quantity_filled}/#{quantity_total}"

      close = process(
        id,
        order_status.downcase.to_sym,
        quantity_filled.to_i,
        price
      )

      stream.close if close
    end

    def process(id, status, quantity, price)
      order = @open_orders[id]
      if order.nil?
        logger.fatal "received order event for unknown order ##{id}"
        return
      end

      case status
      when :partially_filled
        order.quantity -= quantity
        order.emit(status, quantity, price)
      when :filled
        order.quantity = 0
        order.emit(status, quantity, price)
        @open_orders.delete(id)
        return true
      when :canceled
        order.emit(status)
        @open_orders.delete(id)
        return true
      end
    end
  end
end
