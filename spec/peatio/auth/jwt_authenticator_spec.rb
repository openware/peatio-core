describe Peatio::Auth::JWTAuthenticator do

  let(:rsa_private) { OpenSSL::PKey::RSA.generate(2048) }
  let(:rsa_public) { rsa_private.public_key }
  let(:auth) { Peatio::Auth::JWTAuthenticator.new(rsa_public, rsa_private) }
  let(:invalid_auth) { Peatio::Auth::JWTAuthenticator.new(rsa_public, nil) }
  let(:token) { auth.encode(payload) }

  let :payload do
    {
      iat: Time.now.to_i,
      exp: (Time.now + 60).to_i,
      sub: 'session',
      iss: 'barong',
      aud: %w[ peatio barong ],
      jti: 'BEF5617B7B2762DDE61702F5',
      uid: 'TEST123',
      email: 'user@example.com',
      role: 'admin',
      level: 4,
      state: 'active',
    }
  end

  it 'can authenticate valid jwt' do
    auth.authenticate!("Bearer #{token}")
  end

  it 'will raise exception for invalid jwt (expired)' do
    # payload is expired
    payload[:exp] = (Time.now - 60).to_i

    expect do
      auth.authenticate!("Bearer #{token}")
    end.to raise_error(Peatio::Auth::Error)
  end

  it 'will raise exception if no private key given for encoding' do
    expect do
      invalid_auth.encode('xxx')
    end.to raise_error(ArgumentError)
  end

  it 'will raise exception for invalid jwt (garbage)' do
    auth = Peatio::Auth::JWTAuthenticator.new(rsa_public, nil)

    expect do
      invalid_auth.authenticate!('Bearer garbage')
    end.to raise_error(/Authorization failed: Failed to decode and verify JWT/)
  end

  context 'valid issuer' do
    before {ENV['JWT_ISSUER'] = 'qux'}
    before {payload[:iss] = 'qux'}
    after {ENV.delete('JWT_ISSUER')}
    it 'should validate issuer' do
      auth.authenticate!("Bearer #{token}")
    end
  end

  context 'invalid issuer' do
    before { ENV['JWT_ISSUER'] = 'qux' }
    before { payload[:iss] = 'hacker' }
    after  { ENV.delete('JWT_ISSUER') }
    it 'should validate issuer' do
      expect {
        auth.authenticate!("Bearer #{token}")
      }.to raise_error(Peatio::Auth::Error)
    end
  end

  context 'valid audience' do
    before { ENV['JWT_AUDIENCE'] = 'foo,bar' }
    before { payload[:aud] = ['bar'] }
    after  { ENV.delete('JWT_AUDIENCE') }
    it('should validate audience') do
      auth.authenticate!("Bearer #{token}")
    end
  end

  context 'invalid audience' do
    before { ENV['JWT_AUDIENCE'] = 'foo,bar' }
    before { payload[:aud] = ['baz'] }
    after  { ENV.delete('JWT_AUDIENCE') }
    it 'should validate audience' do
      expect do
        auth.authenticate!("Bearer #{token}")
      end.to raise_error(Peatio::Auth::Error)
    end
  end

  context 'missing JWT ID' do
    before { payload[:jti] = nil }
    it 'should require JTI' do
      expect do
        auth.authenticate!("Bearer #{token}")
      end.to raise_error(Peatio::Auth::Error)
    end
  end

  context 'issued at in future' do
    before { payload[:iat] = (Time.now + 10).to_i }
    it 'should not allow JWT' do
      expect do
        auth.authenticate!("Bearer #{token}")
      end.to raise_error(Peatio::Auth::Error)
    end
  end

  context 'issued at before future' do
    before { payload[:iat] = (Time.now - 1).to_i  }
    it('should allow JWT') do
      auth.authenticate!("Bearer #{token}")
    end
  end
end
