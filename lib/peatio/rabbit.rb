module Ranger
  module Rabbit
    def connect!
      Connection.new(host: "0.0.0.0")
    end

    module_function :connect!
  end
end
