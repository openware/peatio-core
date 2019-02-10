module Peatio::WalletService
  class Abstract
    attr_reader :blockchain

    def initialize(wallet:)
      @wallet = wallet
    end

    def create_address(options = {})
      method_not_implemented
    end

    def collect_deposit!(deposit, options = {})
      method_not_implemented
    end

    def build_withdrawal!(withdraw, options = {})
      method_not_implemented
    end

    def deposit_collection_fees(deposit, options = {})
      method_not_implemented
    end

    def load_balance(address, currency)
      method_not_implemented
    end

  end
end
  