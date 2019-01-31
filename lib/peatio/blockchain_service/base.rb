module Peatio::BlockchainService
  class Base
    attr_reader :logger, :cache, :blockchain, :currencies

    def initialize(logger:, cache:, blockchain:, currencies:)
      @logger = logger
      @cache = cache
      @blockchain = blockchain
      @currencies = currencies
    end

    # TODO: Doc
    def fetch_block!
      method_not_implemented
    end

    # TODO: Doc
    def filtered_deposits(addresses, &block)
      method_not_implemented
    end

    # TODO: Doc
    def filtered_withdrawals(txids, &block)
      method_not_implemented
    end

    # TODO: Doc
    def current_block
      method_not_implemented
    end

    # TODO: Doc
    def latest_block
      method_not_implemented
    end

    # TODO: Tricky code!!!
    # TODO: Doc
    def client
      @client ||= self.class.name.sub("Service", "Client").constantize.new(blockchain)
    end

    private
    def cache_key(*suffixes)
      [self.class.name.underscore.sub("/", ":"), suffixes].join(":")
    end
  end
end
