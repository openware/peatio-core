module Peatio
  module WalletService
    module Helpers

      def spread_deposit(deposit)
        left_amount = deposit.amount
        collection_spread = Hash.new(0)
        currency = deposit.currency
        destination_wallets(deposit).each do |wallet|
          break if left_amount == 0
          blockchain_client = BlockchainClient[Blockchain.find_by_key(wallet.blockchain_key).key]
          wallet_balance = blockchain_client.load_balance!(wallet.address, deposit.currency)
          amount_for_wallet = [wallet.max_balance - wallet_balance, left_amount].min
          # If free amount for current wallet too small we will not able to collect it.
          # So we try to collect it to next wallets.
          next if amount_for_wallet < currency.min_collection_amount
          left_amount -= amount_for_wallet
          # If amount left is too small we will not able to collect it.
          # So we collect everything to current wallet.
          if left_amount < currency.min_collection_amount
            amount_for_wallet += left_amount
            left_amount = 0
          end
          collection_spread[wallet.address] = amount_for_wallet if amount_for_wallet > 0
        rescue => e
          # If have exception move to next wallet
          report_exception(e)
        end
        # If deposit doesn't fit to any wallet collect it to last wallet.
        # Last wallet is considered to be the most secure.
        if left_amount > 0
          collection_spread[destination_wallets(deposit).last.address] += left_amount
          left_amount = 0
        end
        unless collection_spread.values.sum == deposit.amount
          raise Error, "Deposit spread failed deposit.amount != collection_spread.values.sum"
        end
  
        Rails.logger.warn { "Deposit collection spread #{collection_spread}." }
        collection_spread
      end

      def destination_wallets(deposit)
        Wallet
          .active
          .withdraw
          .ordered
          .where(currency_id: deposit.currency_id)
      end
    end
  end
end
