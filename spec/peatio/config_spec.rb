describe Peatio::Config do
  it 'Can define attributes' do
    conf = Peatio::Config.new(name: 'John')
    conf.last = 'Doe'
    expect(conf.class).to eq(Peatio::Config)
    expect(conf.name).to eq('John')
    expect(conf.last).to eq('Doe')
  end

  it 'Can define sub-attributes' do
    conf = Peatio::Config.new
    conf.ranger.host = '0.0.0.0'
    conf.ranger.port = 8080
    expect(conf.class).to eq(Peatio::Config)
    expect(conf.ranger.host).to eq('0.0.0.0')
    expect(conf.ranger.port).to eq(8080)
  end
end
