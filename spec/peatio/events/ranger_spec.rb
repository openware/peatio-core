require "em-spec/rspec"
require "bunny-mock"

describe Peatio::Ranger do
  let(:logger) { Peatio::Logger }
  #let(:member) { create(:member, :level_3) }
  #let(:token) { jwt_for(member) }
  #let(:ws_client) { EventMachine::WebSocketClient.connect("ws://#{ENV.fetch("WEBSOCKET_HOST")}:#{ENV.fetch("WEBSOCKET_PORT")}/") }
  #
  let(:jwt_private_key) {
    OpenSSL::PKey::RSA.generate 2048
  }
  let(:jwt_public_key) {
    rsa_private.public_key
  }
  let(:auth) {
    Peatio::Auth::JWTAuthenticator.new(jwt_public_key)
  }

  let(:logger) {
    Peatio::Logger.logger
  }

  include EM::SpecHelper

  context "invalid json data" do
    before do
      Peatio::MQ::Client.new
      Peatio::MQ::Client.connection = BunnyMock.new.start
      Peatio::MQ::Client.create_channel!
    end
    it "connection closed" do
      em {
        ws_server do |socket|
          connection = Connection.new(auth, socket, logger)
          socket.onopen do |handshake|
            connection.handshake(handshake)
          end
          socket.onmessage do |msg|
            connection.handle(msg)
          end
        end
      }
    end
  end
end
