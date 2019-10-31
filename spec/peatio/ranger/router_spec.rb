# frozen_string_literal: true

describe Peatio::Ranger::Router do
  let(:router) { Peatio::Ranger::Router.new() }

  let(:anonymous1) { OpenStruct.new(authorized: false, user: nil, id: 1, streams: []) }
  let(:anonymous2) { OpenStruct.new(authorized: false, user: nil, id: 2, streams: []) }
  let(:user1) { OpenStruct.new(authorized: true, user: "user1", id: 3, streams: []) }
  let(:user2) { OpenStruct.new(authorized: true, user: "user2", id: 4, streams: []) }

  context "unauthorized users" do
    it "registers connections and subscribed streams" do
      # users connect
      router.on_connection_open(anonymous1)
      router.on_connection_open(anonymous2)

      expect(router.connections.size).to eq(2)
      expect(router.connections).to eq(
        anonymous1.id => anonymous1,
        anonymous2.id => anonymous2
      )
      expect(router.connections_by_userid.size).to eq(0)
      expect(router.streams_sockets.size).to eq(0)

      # users subscribe to streams
      router.on_subscribe(anonymous1, "some-feed")
      router.on_subscribe(anonymous2, "some-feed")
      router.on_subscribe(anonymous2, "another-feed")

      expect(router.connections.size).to eq(2)
      expect(router.connections_by_userid.size).to eq(0)
      expect(router.streams_sockets.size).to eq(2)
      expect(router.streams_sockets).to eq(
        "some-feed"    => [anonymous1, anonymous2],
        "another-feed" => [anonymous2]
      )

      # users disconnect
      anonymous1.streams = %w[some-feed]
      anonymous2.streams = %w[some-feed another-feed]
      router.on_connection_close(anonymous1)
      router.on_connection_close(anonymous2)
      expect(router.connections).to eq({})
      expect(router.connections_by_userid).to eq({})
      expect(router.streams_sockets).to eq({})
    end

    it "unsubscribes from streams" do
      # users connect
      router.on_connection_open(anonymous1)
      router.on_connection_open(anonymous2)

      expect(router.connections.size).to eq(2)
      expect(router.connections).to eq(
        anonymous1.id => anonymous1,
        anonymous2.id => anonymous2
      )
      expect(router.connections_by_userid.size).to eq(0)
      expect(router.streams_sockets.size).to eq(0)

      # users subscribe to streams
      router.on_subscribe(anonymous1, "some-feed")
      router.on_subscribe(anonymous2, "some-feed")
      router.on_subscribe(anonymous2, "another-feed")

      expect(router.connections.size).to eq(2)
      expect(router.connections_by_userid.size).to eq(0)
      expect(router.streams_sockets.size).to eq(2)
      expect(router.streams_sockets).to eq(
        "some-feed"    => [anonymous1, anonymous2],
        "another-feed" => [anonymous2]
      )

      # users unsubscribe
      router.on_unsubscribe(anonymous1, "some-feed")
      router.on_unsubscribe(anonymous2, "some-feed")
      router.on_unsubscribe(anonymous2, "another-feed")
      expect(router.connections.size).to eq(2)
      expect(router.connections_by_userid).to eq({})
      expect(router.streams_sockets).to eq({})
    end
  end

  context "authorized users" do
    it "registers connections, subscribed streams and connections by users id" do
      # users connect
      router.on_connection_open(user1)
      router.on_connection_open(user2)

      expect(router.connections.size).to eq(2)
      expect(router.connections).to eq(
        user1.id => user1,
        user2.id => user2
      )
      expect(router.connections_by_userid.size).to eq(2)
      expect(router.connections_by_userid).to eq(
        "user1" => [user1],
        "user2" => [user2]
      )

      expect(router.streams_sockets.size).to eq(0)

      # users disconnect
      router.on_connection_close(user1)
      router.on_connection_close(user2)
      expect(router.connections).to eq({})
      expect(router.connections_by_userid).to eq({})
      expect(router.streams_sockets).to eq({})
    end
  end
end
