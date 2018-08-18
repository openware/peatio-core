# encoding: UTF-8
# frozen_string_literal: true

require "em-spec/rspec"
require "em-websocket"
require "em-websocket-client"

# Start websocket server connection
def ws_server(opts = {})
  EM::WebSocket.run({:host => Peatio::Config.fetch("WEBSOCKET_HOST"), :port => Peatio::Config.fetch("WEBSOCKET_PORT")}.merge(opts)) { |ws|
    yield ws if block_given?
  }
end

def ws_connect(query = "")
  EventMachine::WebSocketClient.connect(
    "ws://#{Peatio::Config.fetch("WEBSOCKET_HOST")}:#{Peatio::Config.fetch("WEBSOCKET_PORT")}" + query,
  )
end
