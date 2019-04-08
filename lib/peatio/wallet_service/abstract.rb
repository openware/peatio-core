module Peatio
  module WalletService
    class Abstract
      def initialize(wallet:)
        @wallet = wallet
      end

      def create_address!(options = {})
        abstract_method
      end

      def collect_deposit!(deposit, options = {})
        abstract_method
      end

      def build_withdrawal!(withdraw, options = {})
        abstract_method
      end

      private
      def abstract_method
        method_not_implemented
      end
    end
  end
end
