describe Peatio::Application do
  it 'Can instanciate a singleton' do
    app = Peatio::Application.instance
    expect(app.class).to eq(Peatio::Application)
  end

  it 'Hold a top level configuration' do
    cnf = Peatio::Application.config
    expect(cnf.class).to eq(Peatio::Config)
  end

  it 'Can configure the application instance' do
    cnf = Peatio::Application.config
    Peatio::Application.configure do |config|
      config.name = 'Ranger'
      config.port = 4242
    end
    expect(cnf.name).to eq('Ranger')
    expect(cnf.port).to eq(4242)
  end

  it 'Can load configuration default per env' do
    app = Peatio::Application.initialize!
    expect(app.config.env).to eq("test")
  end

  it 'Will fail to load incorrect environment' do
    expect {
      app = Peatio::Application.initialize!('stage')
    }.to raise_error(Peatio::Error)
  end

  it 'Can override environment' do
    app = Peatio::Application.initialize!('production')
    expect(app.config.env).to eq('production')
    expect(app.config.log_level).to eq('WARN')
  end
end
