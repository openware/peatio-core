module Peatio
  module WalletService
    class Abstract
      def initialize(wallet:)
        @wallet = wallet
      end

      def create_address!(options = {})
        method_not_implemented
      end

      def collect_deposit!(deposit, options = {})
        method_not_implemented
      end

      def build_withdrawal!(withdraw, options = {})
        method_not_implemented
      end

    end
  end
end
