require "yaml"

module Peatio
  class Config
    class << self
      def load(env)
        @default_config ||= load_config(get_path("default"))

        @config ||= @default_config.merge(load_config(get_path(env)))
      end

      def fetch(name, default_value = nil)
        @config.fetch(name, default_value)
      end

      def get_path(env)
        File.join(
          File.expand_path("../..", File.dirname(__FILE__)),
          "/config/",
          "%s.yaml" % [env]
        )
      end

      def load_config(path)
        if !File.exist?(path)
          raise Peatio::Error.new(code: 2002, text: "Configuration file is missing: #{path}")
        end

        YAML.load(File.open(path).read)
      end
    end
  end
end
