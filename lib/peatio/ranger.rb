module Peatio::Ranger
  def run!
    logger = Peatio::Logger.logger
    port = 8081
    logger.info "Starting the server on port #{port}"

    EM.run do
      Peatio::MQ::Client.new
      Peatio::MQ::Events.subscribe!

      EM::WebSocket.start(host: "0.0.0.0", port: port) do |ws|
        ws.onopen do |id|
          logger.info "WebSocket connection openned"
          ws.instance_variable_set(:@connection_handler, Peatio::MQ::Events::SocketHandler.new(ws))
        end

        ws.onclose { logger.info "WebSocket connection closed" }

        # ws.onmessage do |msg|
        #   logger.debug "Recieved message: #{msg}"
        #   ws.send "Pong: #{msg}"
        # end
      end
    end
  end

  module_function :run!
end
