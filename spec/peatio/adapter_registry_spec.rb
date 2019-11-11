WalletAdapter = Class.new(Peatio::Core::Blockchain::Abstract)
BlockchainAdapter = Class.new(Peatio::Core::Wallet::Abstract)

describe Peatio::Core::AdapterRegistry do
  before do
    Peatio::Core::Blockchain.registry.adapters = {}
    Peatio::Core::Wallet.registry.adapters = {}
  end

  it 'registers adapter' do
    Peatio::Core::Blockchain.registry[:ethereum] = BlockchainAdapter
    expect(Peatio::Core::Blockchain.registry.adapters.count).to eq(1)

    Peatio::Core::Blockchain.registry[:bitcoin] = BlockchainAdapter
    expect(Peatio::Core::Blockchain.registry.adapters.count).to eq(2)

    Peatio::Core::Wallet.registry[:ethereum] = WalletAdapter
    expect(Peatio::Core::Wallet.registry.adapters.count).to eq(1)

    Peatio::Core::Wallet.registry[:bitcoin] = WalletAdapter
    expect(Peatio::Core::Wallet.registry.adapters.count).to eq(2)
  end

  it 'raises error on duplicated name' do
    Peatio::Core::Blockchain.registry[:ethereum] = BlockchainAdapter
    expect { Peatio::Core::Blockchain.registry[:ethereum] = BlockchainAdapter }.to raise_error(Peatio::Core::AdapterRegistry::DuplicatedAdapterError)

    Peatio::Core::Wallet.registry[:ethereum] = WalletAdapter
    expect { Peatio::Core::Wallet.registry[:ethereum] = WalletAdapter }.to raise_error(Peatio::Core::AdapterRegistry::DuplicatedAdapterError)
  end

  it 'returns adapter for blockchain name' do
    Peatio::Core::Blockchain.registry[:ethereum] = BlockchainAdapter
    Peatio::Core::Wallet.registry[:ethereum] = WalletAdapter

    expect(Peatio::Core::Blockchain.registry[:ethereum]).to eq(BlockchainAdapter)
    expect(Peatio::Core::Wallet.registry[:ethereum]).to eq(WalletAdapter)
  end

  it 'raises error for not registered adapter name' do
    expect{ Peatio::Core::Blockchain.registry[:ethereum] }.to raise_error(Peatio::Core::AdapterRegistry::NotRegisteredAdapterError)
  end
end
