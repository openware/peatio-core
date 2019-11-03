# frozen_string_literal: true

module Peatio::Metrics
  class Server
    def self.app(registry)
      Rack::Builder.new do |builder|
        builder.use Rack::CommonLogger
        builder.use Rack::ShowExceptions
        builder.use Rack::Deflater
        builder.use Prometheus::Middleware::Exporter, registry: registry
        builder.run ->(_) { [404, {"Content-Type" => "text/html"}, ["Not found\n"]] }
      end
    end
  end
end
