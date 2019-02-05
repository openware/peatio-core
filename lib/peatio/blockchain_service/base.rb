module Peatio::BlockchainService
  class Base
    attr_reader :cache, :blockchain

    def initialize(cache:, blockchain:)
      @cache = cache
      @blockchain = blockchain
    end

    # TODO: Doc
    def fetch_block!(block_number)
      method_not_implemented
    end

    # TODO: Doc
    def filtered_deposits(payment_addresses, &block)
      method_not_implemented
    end

    # TODO: Doc
    def filtered_withdrawals(withdrawals, &block)
      method_not_implemented
    end

    # TODO: Doc
    def current_block_number
      method_not_implemented
    end

    # TODO: Doc
    def latest_block_number
      method_not_implemented
    end

    protected
    def cache_key(*suffixes)
      [self.class.name.underscore.gsub("/", ":"), suffixes].join(":")
    end
  end
end
