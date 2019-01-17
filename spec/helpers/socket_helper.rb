# encoding: UTF-8
# frozen_string_literal: true

require "em-spec/rspec"
require "em-websocket"
require "em-websocket-client"
require "websocket"

WS_HOST = ENV.fetch("WEBSOCKET_HOST", "0.0.0.0")
WS_PORT = ENV.fetch("WEBSOCKET_PORT", "13579")

class EM::WebSocketClient
  attr_accessor :url
  attr_accessor :protocol_version
  attr_accessor :origin
  attr_accessor :headers

  def self.connect(uri, opts={})
    headers = opts[:headers]
    p_uri = URI.parse(uri)
    conn = EM.connect(p_uri.host, p_uri.port || 80, self) do |c|
      c.url = uri
      c.protocol_version = opts[:version]
      c.origin = opts[:origin]
      c.headers = @headers
    end
  end

  def connection_completed
    @connect.yield if @connect
    pp headers
    @hs = ::WebSocket::Handshake::Client.new(url:     @url,
                                            headers: @headers,
                                            origin:  @origin,
                                            version: @protocol_version)
    pp '@hs', @hs.to_s
    send_data @hs.to_s
  end
end

# Start websocket server connection
def ws_server(opts = {})
  EM::WebSocket.run({ host: WS_HOST, port: WS_PORT }.merge(opts)) { |ws|
    yield ws if block_given?
  }
end

def ws_connect(query = "", headers = {})
  EM::WebSocketClient.connect("ws://#{WS_HOST}:#{WS_PORT}/#{query}", headers: headers)
end
