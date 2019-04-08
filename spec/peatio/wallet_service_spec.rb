EthereumAdapter = Class.new(Peatio::WalletService::Abstract)
BitcoinAdapter = Class.new(Peatio::WalletService::Abstract)

describe Peatio::WalletService do
  before { Peatio::WalletService.adapters = {} }

  it 'registers adapter' do
    Peatio::WalletService.register_adapter(:ethereum, EthereumAdapter)
    expect(Peatio::WalletService.send(:adapters).count).to eq(1)

    Peatio::WalletService.register_adapter(:bitcoin, BitcoinAdapter)
    expect(Peatio::WalletService.send(:adapters).count).to eq(2)
  end

  it 'raises error on duplicated name' do
    Peatio::WalletService.register_adapter(:ethereum, EthereumAdapter)
    expect { Peatio::WalletService.register_adapter(:ethereum, BitcoinAdapter) }.to raise_error(Peatio::WalletService::DuplicatedAdapterError)
  end

  it 'returns adapter for blockchain name' do
    Peatio::WalletService.register_adapter(:ethereum, EthereumAdapter)
    Peatio::WalletService.register_adapter(:bitcoin, BitcoinAdapter)

    expect(Peatio::WalletService.adapter_for(:ethereum)).to eq(EthereumAdapter)
    expect(Peatio::WalletService.adapter_for(:bitcoin)).to eq(BitcoinAdapter)
  end

  it 'raises error for not registered adapter name' do
    expect{ Peatio::WalletService.adapter_for(:ethereum) }.to raise_error(Peatio::WalletService::NotRegisteredAdapterError)
  end
end
