require "em-spec/rspec"
require "bunny-mock"

describe Peatio::Ranger do
  let(:logger) { Peatio::Logger }

  let(:jwt_private_key) {
    OpenSSL::PKey::RSA.generate 2048
  }

  let(:jwt_public_key) {
    jwt_private_key.public_key
  }

  let(:auth) {
    Peatio::Auth::JWTAuthenticator.new(jwt_public_key, jwt_private_key)
  }

  let(:logger) {
    Peatio::Logger.logger
  }

  let(:msg_auth_failed) {
    "{\"error\":{\"message\":\"Authentication failed.\"}}"
  }

  let(:msg_auth_success) {
    "{\"success\":{\"message\":\"Authenticated.\"}}"
  }

  let(:valid_token_payload) {
    {
      :iat => 1534242281,
      :exp => (Time.now + 3600).to_i,
      :sub => "session",
      :iss => "barong",
      :aud => ["peatio", "barong"],
      :jti => "BEF5617B7B2762DDE61702F5",
      :uid => "IDE8E2280FD1",
      :email => "email@heliostech.fr",
      :role => "admin",
      :level => 4,
      :state => "active"
    }
  }

  let(:valid_token) {
    auth.encode(valid_token_payload)
  }

  include EM::SpecHelper

  context "invalid token" do
    before do
      Peatio::MQ::Client.new
      Peatio::MQ::Client.connection = BunnyMock.new.start
      Peatio::MQ::Client.create_channel!
    end

    it "denies access" do
      em {
        EM.add_timer(1) { fail "timeout" }

        ws_server do |socket|
          connection = Peatio::Ranger::Connection.new(auth, socket, logger)
          socket.onopen do |handshake|
            connection.handshake(handshake)
          end
          socket.onmessage do |msg|
            connection.handle(msg)
          end
          socket.onerror do |e|
            expect(e.message).to eq "Authorization failed"
            logger.error "ranger: WebSocket Error: #{e.message}"
          end
        end

        EM.add_timer(0.1) do
          token = auth.encode("")
          wsc = ws_connect("", { "Authorization" => "Bearer #{token}" })
          wsc.disconnect { done }
        end
      }
    end

  end

  context "valid token" do
    before do
      Peatio::MQ::Client.new
      Peatio::MQ::Client.connection = BunnyMock.new.start
      Peatio::MQ::Client.create_channel!
    end

    it "allows access" do
      em {
        EM.add_timer(1) { fail "timeout" }
        ws_server do |socket|
          connection = Peatio::Ranger::Connection.new(auth, socket, logger)

          socket.onopen do |handshake|
            connection.handshake(handshake)
          end

          socket.onerror do |e|
            logger.error "ranger: WebSocket Error: #{e.message}"
          end

          socket.onmessage do |msg|
            connection.handle(msg)
          end
        end


        EM.add_timer(0.1) do
          wsc = ws_connect("", { "Authorization" => "Bearer #{valid_token}" })
          wsc.callback {
            logger.info "Connected"
            expect("ok").to eq "ok"
            done
          }
          wsc.disconnect { done }
        end
      }
    end
  end

  context "valid token" do
    before do
      Peatio::MQ::Client.new
      Peatio::MQ::Client.connection = BunnyMock.new.start
      Peatio::MQ::Client.create_channel!

      Peatio::MQ::Events.subscribe!
    end

    it "sends messages that belong to the user and filtered by stream" do
      em {
        EM.add_timer(1) { fail "timeout" }

        ws_server do |socket|
          connection = Peatio::Ranger::Connection.new(auth, socket, logger)

          socket.onopen do |handshake|
            connection.handshake(handshake)
          end

          socket.onmessage do |msg|
            connection.handle(msg)
          end
        end

        EM.add_timer(0.1) do
          wsc = ws_connect("/?stream=stream_1&stream=stream_2", { "Authorization" => "Bearer #{valid_token}" })

          wsc.callback {
            Peatio::MQ::Events.publish("private", valid_token_payload[:uid], "stream_1", {
              key: "stream_1_user_1",
            })
            Peatio::MQ::Events.publish("private", "SOMEUSER2", "stream_1", {
              key: "stream_1_user_2",
            })
            Peatio::MQ::Events.publish("private", valid_token_payload[:uid], "stream_2", {
              key: "stream_2_user_1",
            })
            Peatio::MQ::Events.publish("private", valid_token_payload[:uid], "stream_3", {
              key: "stream_3_user_1",
            })
            Peatio::MQ::Events.publish("private", valid_token_payload[:uid], "stream_2", {
              key: "stream_2_user_1_message_2",
            })
          }

          step = 0
          wsc.stream { |msg|
            step += 1
            logger.debug "Received: #{msg}"
            case step
            when 1
              expect(msg.data).to eq '{"stream_1":{"key":"stream_1_user_1"}}'
            when 2
              expect(msg.data).to eq '{"stream_2":{"key":"stream_2_user_1"}}'
            when 3
              expect(msg.data).to eq '{"stream_2":{"key":"stream_2_user_1_message_2"}}'
              done
            end
          }
          wsc.disconnect { done }
        end
      }
    end

    it "sends public messages filtered by stream" do
      em {
        EM.add_timer(1) { fail "timeout" }
        ws_server do |socket|
          connection = Peatio::Ranger::Connection.new(auth, socket, logger)

          socket.onopen do |handshake|
            connection.handshake(handshake)
          end

          socket.onmessage do |msg|
            connection.handle(msg)
          end
        end

        EM.add_timer(0.1) do
          ws_client = ws_connect("/?stream=btcusd.order")

          ws_client.callback {
            Peatio::MQ::Events.publish("public", "btcusd", "order", {
              key: "btcusd_order_1",
            })
            Peatio::MQ::Events.publish("public", "btcusd", "order", {
              key: "btcusd_order_2",
            })
            Peatio::MQ::Events.publish("public", "btcusd", "trade", {
              key: "btcusd_trade_2",
            })
            Peatio::MQ::Events.publish("public", "ethusd", "order", {
              key: "ethusd_order_1",
            })
            Peatio::MQ::Events.publish("public", "btcusd", "order", {
              key: "btcusd_order_3",
            })
          }

          step = 0
          ws_client.stream { |msg|
            step += 1

            case step
            when 1
              expect(msg.data).to eq '{"btcusd.order":{"key":"btcusd_order_1"}}'
            when 2
              expect(msg.data).to eq '{"btcusd.order":{"key":"btcusd_order_2"}}'
            when 3
              expect(msg.data).to eq '{"btcusd.order":{"key":"btcusd_order_3"}}'
              done
            end
          }
          ws_client.disconnect { done }
        end

      }
    end

    it "subscribes to streams dynamically and receive public messages filtered by stream" do
      em {
        EM.add_timer(1) { fail "timeout" }
        ws_server do |socket|
          connection = Peatio::Ranger::Connection.new(auth, socket, logger)

          socket.onopen do |handshake|
            connection.handshake(handshake)
          end

          socket.onmessage do |msg|
            connection.handle(msg)
          end
        end

        EM.add_timer(0.1) do
          ws_client = ws_connect("/")

          ws_client.callback do
            ws_client.send_msg(JSON.dump({event: "subscribe", streams: ["btcusd.order"]}))

            EM.add_timer(0.1) do
              Peatio::MQ::Events.publish("public", "btcusd", "order", {
                key: "btcusd_order_1",
              })
              Peatio::MQ::Events.publish("public", "btcusd", "order", {
                key: "btcusd_order_2",
              })
              Peatio::MQ::Events.publish("public", "btcusd", "trade", {
                key: "btcusd_trade_2",
              })
              Peatio::MQ::Events.publish("public", "ethusd", "order", {
                key: "ethusd_order_1",
              })
              Peatio::MQ::Events.publish("public", "btcusd", "order", {
                key: "btcusd_order_3",
              })
            end
          end

          step = 0
          ws_client.stream do |msg|
            step += 1

            case step
            when 1
              expect(JSON.load(msg.data)).to eq({"success" => {"message" => "subscribed","streams" => ["btcusd.order"]}})
            when 2
              expect(msg.data).to eq '{"btcusd.order":{"key":"btcusd_order_1"}}'
            when 3
              expect(msg.data).to eq '{"btcusd.order":{"key":"btcusd_order_2"}}'
            when 4
              expect(msg.data).to eq '{"btcusd.order":{"key":"btcusd_order_3"}}'
              done
            end
          end
          EM.add_timer(1) do
            fail "Timeout"
          end

          ws_client.disconnect { done }
        end
      }
    end

    it "unsubscribe a stream stop receiving message for this stream" do
      em {
        EM.add_timer(1) { fail "timeout" }
        ws_server do |socket|
          connection = Peatio::Ranger::Connection.new(auth, socket, logger)

          socket.onopen do |handshake|
            connection.handshake(handshake)
          end

          socket.onmessage do |msg|
            connection.handle(msg)
          end
        end

        EM.add_timer(0.1) do
          ws_client = ws_connect("/?stream=btcusd.order")

          ws_client.callback do
            EM.add_timer(0.1) do
              ws_client.send_msg(JSON.dump({event: "unsubscribe", streams: ["btcusd.order"]}))

              EM.add_timer(0.1) do
                Peatio::MQ::Events.publish("public", "btcusd", "order", {
                  key: "btcusd_order_1",
                })
                Peatio::MQ::Events.publish("public", "btcusd", "order", {
                  key: "btcusd_order_2",
                })
                Peatio::MQ::Events.publish("public", "btcusd", "trade", {
                  key: "btcusd_trade_2",
                })
                Peatio::MQ::Events.publish("public", "ethusd", "order", {
                  key: "ethusd_order_1",
                })
                Peatio::MQ::Events.publish("public", "btcusd", "order", {
                  key: "btcusd_order_3",
                })

                EM.add_timer(0.1) do
                  done
                end
              end
            end
          end

          step = 0
          ws_client.stream do |msg|
            step += 1

            case step
            when 1
              expect(JSON.load(msg.data)).to eq({"success" => {"message" => "unsubscribed","streams" => []}})
            else
              fail "Unexpected message: #{msg}"
            end
          end
          ws_client.disconnect { done }
        end

      }
    end

  end
end
