# frozen_string_literal: true

describe Peatio::Ranger::Router do
  let(:router) { Peatio::Ranger::Router.new(registry) }
  let(:registry) { Prometheus::Client::Registry.new }
  let(:anonymous1) { OpenStruct.new(authorized: false, user: nil, id: 1, streams: {}) }
  let(:anonymous2) { OpenStruct.new(authorized: false, user: nil, id: 2, streams: {}) }
  let(:user1) { OpenStruct.new(authorized: true, user: "user1", id: 3, streams: {}) }
  let(:user2) { OpenStruct.new(authorized: true, user: "user2", id: 4, streams: {}) }

  context "snapshot? method" do
    it "returns true if the stream name suffixed by -snap" do
      expect(router.snapshot?("anything-snap")).to eq(true)
    end

    it "returns false if the stream name is not suffixed by -snap" do
      expect(router.snapshot?("anything-else")).to eq(false)
    end
  end

  context "increment? method" do
    it "returns true if the stream name suffixed by -inc" do
      expect(router.increment?("anything-inc")).to eq(true)
    end

    it "returns false if the stream name is not suffixed by -snap" do
      expect(router.increment?("anything-else")).to eq(false)
    end
  end

  context "storekey method" do
    it "returns the same store key for snapshots and increment streams" do
      expect(router.storekey("anything-inc")).to eq("anything")
      expect(router.storekey("anything-snap")).to eq("anything")
    end
  end

  context "no connection" do
    it "shows empty stats" do
      expect(router.stats).to eq(
        "==== Metrics ====\n" \
        "ranger_connections_total{auth=\"public\"}: 0\n" \
        "ranger_connections_total{auth=\"private\"}: 0\n" \
        "ranger_connections_current{auth=\"public\"}: 0\n" \
        "ranger_connections_current{auth=\"private\"}: 0\n" \
        "ranger_subscriptions_current: 0\n" \
        "ranger_streams_kinds: 0"
      )
    end
  end

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
      anonymous1.streams = {"some-feed" => true}
      anonymous2.streams = {"some-feed" => true, "another-feed" => true}
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
      expect(router.stats).to eq(
        "==== Metrics ====\n" \
        "ranger_connections_total{auth=\"public\"}: 2\n" \
        "ranger_connections_total{auth=\"private\"}: 0\n" \
        "ranger_connections_current{auth=\"public\"}: 2\n" \
        "ranger_connections_current{auth=\"private\"}: 0\n" \
        "ranger_subscriptions_current: 3\n" \
        "ranger_streams_kinds: 2"
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

  context "incremental objects store" do
    let(:cnx1) { double(id: 1) }
    let(:delivery_snap) { double(routing_key: "public.abc.object-snap") }
    let(:delivery_inc) { double(routing_key: "public.abc.object-inc") }
    let(:snapshot1) { JSON.dump([1, 2, 3]) }
    let(:snapshot2) { JSON.dump([1, 2, 3, 4]) }
    let(:increment1) { JSON.dump([4]) }
    let(:increment2) { JSON.dump([5]) }
    let(:msg_snapshot1) { JSON.dump("abc.object-snap" => [1, 2, 3]) }
    let(:msg_snapshot2) { JSON.dump("abc.object-snap" => [1, 2, 3, 4]) }
    let(:msg_increment1) { JSON.dump("abc.object-inc" => [4]) }
    let(:msg_increment2) { JSON.dump("abc.object-inc" => [5]) }

    it "sends snapshots and increments on subscribe" do
      router.on_message(delivery_snap, nil, snapshot1)
      router.on_message(delivery_inc, nil, increment1)

      expect(cnx1).to receive(:send_raw).with(msg_snapshot1).ordered
      expect(cnx1).to receive(:send_raw).with(msg_increment1).ordered

      router.on_subscribe(cnx1, "abc.object-inc")
    end

    it "sends increments as they come after subscribed and no more snapshot" do
      router.on_message(delivery_snap, nil, snapshot1)
      router.on_message(delivery_inc, nil, increment1)

      expect(cnx1).to receive(:send_raw).with(msg_snapshot1).ordered
      expect(cnx1).to receive(:send_raw).with(msg_increment1).ordered
      router.on_subscribe(cnx1, "abc.object-inc")

      expect(cnx1).to receive(:send_raw).with(msg_increment2).ordered
      router.on_message(delivery_snap, nil, snapshot2)
      router.on_message(delivery_inc, nil, increment2)
    end

    it "does not send any increment before a first snapshot is received by ranger" do
      expect(cnx1).to receive(:send_raw).with(msg_snapshot2).ordered
      expect(cnx1).to receive(:send_raw).with(msg_increment2).ordered

      router.on_message(delivery_inc, nil, increment1)
      router.on_subscribe(cnx1, "abc.object-inc")
      router.on_message(delivery_snap, nil, snapshot2)
      router.on_message(delivery_inc, nil, increment2)
    end
  end
end
