EthereumAdapter = Class.new(Peatio::BlockchainService::Abstract)
BitcoinAdapter = Class.new(Peatio::BlockchainService::Abstract)

describe Peatio::BlockchainService do
  before { Peatio::BlockchainService.adapters = {} }

  it 'registers adapter' do
    Peatio::BlockchainService.register_adapter(:ethereum, EthereumAdapter)
    expect(Peatio::BlockchainService.send(:adapters).count).to eq(1)

    Peatio::BlockchainService.register_adapter(:bitcoin, BitcoinAdapter)
    expect(Peatio::BlockchainService.send(:adapters).count).to eq(2)
  end

  it 'raises error on duplicated name' do
    Peatio::BlockchainService.register_adapter(:ethereum, EthereumAdapter)
    expect { Peatio::BlockchainService.register_adapter(:ethereum, BitcoinAdapter) }.to raise_error(Peatio::BlockchainService::DuplicatedAdapterError)
  end

  it 'returns adapter for blockchain name' do
    Peatio::BlockchainService.register_adapter(:ethereum, EthereumAdapter)
    Peatio::BlockchainService.register_adapter(:bitcoin, BitcoinAdapter)

    expect(Peatio::BlockchainService.adapter_for(:ethereum)).to eq(EthereumAdapter)
    expect(Peatio::BlockchainService.adapter_for(:bitcoin)).to eq(BitcoinAdapter)
  end

  it 'raises error for not registered adapter name' do
    expect{ Peatio::BlockchainService.adapter_for(:ethereum) }.to raise_error(Peatio::BlockchainService::NotRegisteredAdapterError)
  end
end
