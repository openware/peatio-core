# frozen_string_literal: true

module Peatio::Ranger
  class Router
    attr_reader :connections
    attr_reader :connections_by_userid
    attr_reader :streams_sockets
    attr_reader :logger

    class ConnectionArray < Array
      def delete(connection)
        delete_if do |c|
          c.id == connection.id
        end
      end
    end

    def initialize
      @connections = {}
      @connections_by_userid = {}
      @streams_sockets = {}
      @logger = Peatio::Logger.logger
      @stores = {}
    end

    def snapshot?(stream)
      stream.end_with?("-snap")
    end

    def increment?(stream)
      stream.end_with?("-inc")
    end

    def storekey(stream)
      stream.gsub(/-(snap|inc)$/, "")
    end

    def stats
      [
        "==== Stats ====",
        "Connections: %d" % [@connections.size],
        "Authenticated connections: %d" % [@connections_by_userid.each_value.map(&:size).reduce(:+) || 0],
        "Streams subscriptions: %d" % [@streams_sockets.each_value.map(&:size).reduce(:+) || 0],
        "Streams kind: %d" % [@streams_sockets.size],
      ].join("\n")
    end

    def debug
      [
        "==== Debug ====",
        "connections: %s" % [@connections.inspect],
        "connections_by_userid: %s" % [@connections_by_userid],
        "streams_sockets: %s" % [@streams_sockets],
      ].join("\n")
    end

    def on_connection_open(connection)
      @connections[connection.id] = connection
      return unless connection.authorized

      @connections_by_userid[connection.user] ||= ConnectionArray.new
      @connections_by_userid[connection.user] << connection
    end

    def on_connection_close(connection)
      @connections.delete(connection.id)
      connection.streams.keys.each do |stream|
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
      send_snapshot_and_increments(connection, storekey(stream)) if increment?(stream)
    end

    def send_snapshot_and_increments(connection, key)
      return unless @stores[key]
      return unless @stores[key][:snapshot]

      connection.send_raw(@stores[key][:snapshot])
      @stores[key][:increments]&.each {|inc| connection.send_raw(inc) }
    end

    def on_unsubscribe(connection, stream)
      return unless @streams_sockets[stream]

      @streams_sockets[stream].delete(connection)
      @streams_sockets.delete(stream) if @streams_sockets[stream].empty?
    end

    def send_private_message(user_id, event, payload_decoded)
      Array(@connections_by_userid[user_id]).each do |connection|
        connection.send(event, payload_decoded) if connection.streams.include?(event)
      end
    end

    def send_public_message(stream, raw_message)
      Array(@streams_sockets[stream]).each do |connection|
        connection.send_raw(raw_message)
      end
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
        logger.error { "invalid routing key from amqp: #{routing_key}" }
        return
      end

      type, id, event = routing_key.split(".")
      payload_decoded = JSON.parse(payload)

      if type == "private"
        send_private_message(id, event, payload_decoded)
        return
      end

      stream = [id, event].join(".")
      message = JSON.dump(stream => payload_decoded)

      if snapshot?(event)
        key = storekey(stream)

        unless @stores[key]
          # Send the snapshot to subscribers of -inc stream if there were no snapshot before
          send_public_message("#{key}-inc", message)
        end

        @stores[key] = {
          snapshot:   message,
          increments: [],
        }
        return
      end

      if increment?(event)
        key = storekey(stream)

        unless @stores[key]
          logger.warn { "Discard increment received before snapshot for store:#{key}" }
          return
        end

        @stores[key][:increments] << message
      end

      send_public_message(stream, message)
    end
  end
end
