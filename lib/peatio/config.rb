module Peatio
  class Config
    Defaults = {
      WEBSOCKET_HOST: "localhost",
      WEBSOCKET_PORT: "8081",
    }

    class << self
      def fetch(name)
        if ENV[name.to_s]
          return ENV[name.to_s]
        end
        return Defaults[name.to_sym]
      end
    end
  end
end
