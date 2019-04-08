module Peatio
  module BlockchainService
    class Abstract
      attr_reader :blockchain

      def initialize(cache:, blockchain:)
        @cache = cache
        @blockchain = blockchain
      end

      # TODO: Doc
      def fetch_block!(block_number)
        abstract_method
      end

      # TODO: Doc
      def filtered_deposits(payment_addresses, &block)
        abstract_method
      end

      # TODO: Doc
      def filtered_withdrawals(withdrawals, &block)
        abstract_method
      end

      # TODO: Doc
      def current_block_number
        abstract_method
      end

      # TODO: Doc
      def latest_block_number
        abstract_method
      end

      # TODO: Doc
      def client
        abstract_method
      end

      # TODO: Doc
      def supports_cash_addr_format?
        abstract_method
      end

      # TODO: Doc
      def case_sensitive?
        abstract_method
      end

      private
      def abstract_method
        method_not_implemented
      end
    end
  end
end
