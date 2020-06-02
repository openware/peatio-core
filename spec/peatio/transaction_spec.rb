require 'pry-byebug'

describe Peatio::Transaction do
  context :validations do
    let(:transaction_attrs) do
      { hash:         'txid',
        txout:        2,
        from_addresses: ['from_address'],
        to_address:   'to_address',
        amount:       10,
        block_number: 1042,
        currency_id:  'btc',
        status:       'pending' }
    end

    context :presence do
      let(:required_attrs) do
        %i[to_address amount currency_id]
      end

      it 'initialize valid transaction' do
        expect(Peatio::Transaction.new(transaction_attrs).valid?).to be_truthy
      end

      it 'validates presence' do
        required_attrs.each do |attr|
          expect(Peatio::Transaction.new(transaction_attrs.except(attr)).valid?).to be_falsey
        end
      end

      context 'success transaction' do
        before { transaction_attrs[:status] = 'success' }

        let(:required_attrs) do
          %i[hash block_number txout]
        end

        it 'initialize valid transaction' do
          expect(Peatio::Transaction.new(transaction_attrs).valid?).to be_truthy
        end

        it 'validates presence' do
          required_attrs.each do |attr|
            expect(Peatio::Transaction.new(transaction_attrs.except(attr)).valid?).to be_falsey
          end
        end
      end

      context 'failed transaction' do
        before { transaction_attrs[:status] = 'failed' }

        let(:required_attrs) do
          %i[hash block_number]
        end

        it 'initialize valid transaction' do
          expect(Peatio::Transaction.new(transaction_attrs).valid?).to be_truthy
        end

        it 'validates presence' do
          required_attrs.each do |attr|
            expect(Peatio::Transaction.new(transaction_attrs.except(attr)).valid?).to be_falsey
          end
        end
      end
    end

    context :numericality do
      it 'initialize valid transaction' do
        expect(Peatio::Transaction.new(transaction_attrs).valid?).to be_truthy
      end

      it 'validates amount to be number' do
        transaction_attrs[:amount] = 'abc'
        expect(Peatio::Transaction.new(transaction_attrs).valid?).to be_falsey
      end

      it 'validates block_number to be number' do
        transaction_attrs[:block_number] = 'abc'
        expect(Peatio::Transaction.new(transaction_attrs).valid?).to be_falsey
      end

      it 'validates block_number to be integer' do
        transaction_attrs[:block_number] = 10.10
        expect(Peatio::Transaction.new(transaction_attrs).valid?).to be_falsey
      end
    end

    context :inclusion do
      it 'requires status inclusion in STATUSES' do
        transaction_attrs[:block_number] = 'other'
        expect(Peatio::Transaction.new(transaction_attrs).valid?).to be_falsey
      end
    end
  end

  context :initialize do
    let(:transaction_attrs) do
      { hash:         'txid',
        txout:        2,
        to_address:   'to_address',
        amount:       10,
        block_number: 1042,
        currency_id:  'btc',
        status:       'pending' }
    end

    it 'sets default status to pending' do
      transaction_attrs[:status] = nil
      expect(Peatio::Transaction.new(transaction_attrs).status).to eq 'pending'
    end

    it 'converts status to string' do
      transaction_attrs[:status] = :success
      expect(Peatio::Transaction.new(transaction_attrs).status).to eq 'success'
    end
  end

  context :status do
    let(:transaction_attrs) do
      { hash:         'txid',
        txout:        2,
        to_address:   'to_address',
        amount:       10,
        block_number: 1042,
        currency_id:  'btc',
        status:       'pending' }
    end

    it 'wraps status to StringInquirer' do
      transaction = Peatio::Transaction.new(transaction_attrs)
      expect(transaction.status).to be_a(ActiveSupport::StringInquirer)
      expect(transaction.status).to be_respond_to(:pending?)
    end
  end
end
