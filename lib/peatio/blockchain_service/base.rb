module Peatio::BlockchainService
  class Base
    def initialize(options = {})
      @opt = options
    end

    def process_blockchain()
      method_not_implemented
    end
  end
end
