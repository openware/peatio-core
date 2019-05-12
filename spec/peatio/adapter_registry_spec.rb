WalletAdapter = Class.new(Peatio::Blockchain::Abstract)
BlockchainAdapter = Class.new(Peatio::Wallet::Abstract)

describe Peatio::AdapterRegistry do
  before do
    Peatio::Blockchain.registry.adapters = {}
    Peatio::Wallet.registry.adapters = {}
  end

  it 'registers adapter' do
    Peatio::Blockchain.registry[:ethereum] = BlockchainAdapter
    expect(Peatio::Blockchain.registry.adapters.count).to eq(1)

    Peatio::Blockchain.registry[:bitcoin] = BlockchainAdapter
    expect(Peatio::Blockchain.registry.adapters.count).to eq(2)

    Peatio::Wallet.registry[:ethereum] = WalletAdapter
    expect(Peatio::Wallet.registry.adapters.count).to eq(1)

    Peatio::Wallet.registry[:bitcoin] = WalletAdapter
    expect(Peatio::Wallet.registry.adapters.count).to eq(2)
  end

  it 'raises error on duplicated name' do
    Peatio::Blockchain.registry[:ethereum] = BlockchainAdapter
    expect { Peatio::Blockchain.registry[:ethereum] = BlockchainAdapter }.to raise_error(Peatio::AdapterRegistry::DuplicatedAdapterError)

    Peatio::Wallet.registry[:ethereum] = WalletAdapter
    expect { Peatio::Wallet.registry[:ethereum] = WalletAdapter }.to raise_error(Peatio::AdapterRegistry::DuplicatedAdapterError)
  end

  it 'returns adapter for blockchain name' do
    Peatio::Blockchain.registry[:ethereum] = BlockchainAdapter
    Peatio::Wallet.registry[:ethereum] = WalletAdapter

    expect(Peatio::Blockchain.registry[:ethereum]).to eq(BlockchainAdapter)
    expect(Peatio::Wallet.registry[:ethereum]).to eq(WalletAdapter)
  end

  it 'raises error for not registered adapter name' do
    expect{ Peatio::Blockchain.registry[:ethereum] }.to raise_error(Peatio::AdapterRegistry::NotRegisteredAdapterError)
  end
end
