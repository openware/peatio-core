# frozen_string_literal: true

module Peatio::Ranger
  class Events
    def self.publish(type, id, event, payload, opts={})
      ex_name = opts[:ex_name] || "peatio.events.ranger"
      @client ||= Peatio::MQ::Client.new
      @client.publish(ex_name, type, id, event, payload)
    end
  end
end
