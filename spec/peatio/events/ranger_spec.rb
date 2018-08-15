require "em-spec/rspec"
require "bunny-mock"

describe Peatio::Ranger do
  #let(:conn) { BunnyMock.new.start }

  #let(:conn) { BunnyMock.new.start }
  #let(:channel) { conn.channel }
  #let(:logger) { Rails.logger }
  #let(:member) { create(:member, :level_3) }
  #let(:token) { jwt_for(member) }
  #let(:ws_client) { EventMachine::WebSocketClient.connect("ws://#{ENV.fetch("WEBSOCKET_HOST")}:#{ENV.fetch("WEBSOCKET_PORT")}/") }

  include EM::SpecHelper

  context "invalid json data" do
    before do
      Peatio::MQ::Client.new

      Peatio::MQ::Client.connection = BunnyMock.new.start

      Peatio::MQ::Client.create_channel!
    end
    it "connection closed" do
      em {
        ws_server do |ws|
          // @TODO
        end
      }
    end
  end
end
