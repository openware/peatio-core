# frozen_string_literal: true

module Peatio::Command::Service
  class Start < Peatio::Command::Base
    class Ranger < Peatio::Command::Base
      option ["-e", "--exchange"], "NAME", "exchange name to inject messages to", default: "peatio.events.ranger"
      option "--[no-]stats", :flag, "display periodically connections statistics", default: true
      option "--stats-period", "SECONDS", "period of displaying stats in seconds", default: 30
      def execute
        raise ArgumentError, "JWT_PUBLIC_KEY was not specified." if ENV["JWT_PUBLIC_KEY"].to_s.empty?

        key_decoded = Base64.urlsafe_decode64(ENV["JWT_PUBLIC_KEY"])

        jwt_public_key = OpenSSL::PKey.read(key_decoded)
        if jwt_public_key.private?
          raise ArgumentError, "JWT_PUBLIC_KEY was set to private key, however it should be public."
        end

        raise "stats period missing" if stats? && !stats_period

        Prometheus::Client.config.data_store = Prometheus::Client::DataStores::SingleThreaded.new()
        registry = Prometheus::Client.registry

        opts = {
          display_stats: stats?,
          stats_period:  stats_period.to_f,
          metrics_port:  8082,
          registry:      registry
        }
        ::Peatio::Ranger.run!(jwt_public_key, exchange, opts)
      end
    end

    subcommand "ranger", "Start ranger process", Ranger
  end

  class Root < Peatio::Command::Base
    subcommand "start", "Start a service", Start
  end
end
