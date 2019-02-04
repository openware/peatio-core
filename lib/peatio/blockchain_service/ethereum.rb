module Peatio::BlockchainService
  class Ethereum < Base

    # attr_reader :current_block

    def fetch_block!(block_number)
      if blockchain.height >= latest_block
        Rails.logger.info { "Skip synchronization. No new blocks detected height: #{blockchain.height}, latest_block: #{latest_block}" }
        nil
      end
      # TODO: Do we need @current_block here ???
      @current_block = block_number
      @block_json = client.get_block(@current_block)
      if @block_json.blank? || @block_json['transactions'].blank?
        # TODO: Do something special!!!
      end
    end

    def latest_block
      cache.fetch(cache_key(:latest_block), expires_in: 5.seconds) do
        client.latest_block_number
      end
    end

    def current_block
      puts "current-block = #{@current_block}"
      @current_block
    end

    def client
      ::BlockchainClient::Ethereum.new(@blockchain)
    end

    def filtered_deposits(payment_addresses, &block)
      @block_json
        .fetch('transactions')
        .each_with_object([]) do |block_txn, deposits|

        if block_txn.fetch('input').hex <= 0
          txn = block_txn
          next if client.invalid_eth_transaction?(txn)
        else
          txn = client.get_txn_receipt(block_txn.fetch('hash'))
          if txn.nil? || client.invalid_erc20_transaction?(txn)
            deposits << { txid: block_txn.fetch('hash')}
            next
          end
        end

        payment_addresses
          .where(address: client.to_address(txn))
          .each do |payment_address|
            deposit_txs = client.build_transaction(txn, @block_json,
                                                   payment_address.address,
                                                   payment_address.currency)
            deposit_txs.fetch(:entries).each do |entry|
              deposit = { txid:           deposit_txs[:id],
                          address:        entry[:address],
                          amount:         entry[:amount],
                          member:         payment_address.account.member,
                          currency:       payment_address.currency,
                          txout:          entry[:txout],
                          block_number:   deposit_txs[:block_number] }

              block.call(deposit) if block_given? # Is it right ?
              deposits << deposit
            end
          end
      end
    end

    def filtered_withdrawals(withdrawals, &block)
      @block_json
        .fetch('transactions')
        .each_with_object([]) do |block_txn, withdrawals_h|

        withdrawals
          .where(txid: block_txn.fetch('hash'))
          .each do |withdraw|

          # TODO: Check this.
          if block_txn.fetch('input').hex <= 0
            txn = block_txn
            next if client.invalid_eth_transaction?(txn)
          else
            txn = client.get_txn_receipt(block_txn.fetch('hash'))
            if txn.nil? || client.invalid_erc20_transaction?(txn)
              # withdrawals_h << { txid: block_txn.fetch('hash')}
              # next
            end
          end

          withdraw_txs = client.build_transaction(txn, @block_json, withdraw.rid, withdraw.currency)  # block_txn required for ETH transaction
          withdraw_txs.fetch(:entries).each do |entry|
            withdrawal =  { txid:           withdraw_txs[:id],
                            rid:            entry[:address],
                            amount:         entry[:amount],
                            block_number:   withdraw_txs[:block_number] }
            block.call(withdrawal) if block_given?
            withdrawals_h << withdrawal
          end
        end
      end
    end
  end
end
