# frozen_string_literal: true

module Peatio::Ranger
  class Router
    attr_reader :connections
    attr_reader :connections_by_userid
    attr_reader :streams_sockets

    class ConnectionArray < Array
      def delete(connection)
        self.delete_if do |c|
          c.id == connection.id
        end
      end
    end

    def initialize
      @connections = {}
      @connections_by_userid = {}
      @streams_sockets = {}
    end

    def on_connection_open(connection)
      @connections[connection.id] = connection
      return unless connection.authorized

      @connections_by_userid[connection.user] ||= ConnectionArray.new
      @connections_by_userid[connection.user] << connection
    end

    def on_connection_close(connection)
      @connections.delete(connection.id)

      connection.streams.each do |stream|
        on_unsubscribe(connection, stream)
      end
      return unless connection.authorized

      @connections_by_userid[connection.user].delete(connection)
      @connections_by_userid.delete(connection.user) \
        if @connections_by_userid[connection.user].empty?
    end

    def on_subscribe(connection, stream)
      @streams_sockets[stream] ||= ConnectionArray.new
      @streams_sockets[stream] << connection
    end

    def on_unsubscribe(connection, stream)
      return unless @streams_sockets[stream]

      @streams_sockets[stream].delete(connection)
      @streams_sockets.delete(stream) if @streams_sockets[stream].empty?
    end

    #
    # routing key format: type.id.event
    # * `type` can be *public* or *private*
    # * `id` can be user id or market id
    # * `event` is the event identifier, ex: order_completed, trade, ...
    #
    def on_message(delivery_info, _metadata, payload)
      routing_key = delivery_info.routing_key
      if routing_key.count(".") != 2
        Peatio::Logger.error { "invalid routing key from amqp: #{routing_key}" }
        return
      end

      type, id, event = routing_key.split(".")
      payload_decoded = JSON.parse(payload)

      if type == "private"
        Array(@connections_by_userid[id]).each do |connection|
          connection.send(event, payload_decoded) if connection.streams.include?(event)
        end

        return
      end

      stream = [id, event].join(".")
      message = JSON.dump(stream => payload_decoded)

      Array(@streams_sockets[stream]).each do |connection|
        connection.send_raw(message)
      end
    end
  end
end
