describe Peatio::Auth::JWTAuthenticator do
  it "can authenticate valid jwt" do
    rsa_private = OpenSSL::PKey::RSA.generate(2048)
    rsa_public = rsa_private.public_key

    payload = {
      iat: Time.now.to_i,
      exp: (Time.now + 60).to_i,
      sub: "session",
      iss: "barong",
      aud: [
        "peatio",
        "barong",
      ],
      jti: "BEF5617B7B2762DDE61702F5",
      uid: "TEST123",
      email: "user@example.com",
      role: "admin",
      level: 4,
      state: "active",
    }

    auth = Peatio::Auth::JWTAuthenticator.new(rsa_public, rsa_private)

    token = auth.encode(payload)
    auth.authenticate!("Bearer #{token}")
  end

  it "will raise exception for invalid jwt (expired)" do
    rsa_private = OpenSSL::PKey::RSA.generate(2048)
    rsa_public = rsa_private.public_key

    # payload is expired
    payload = {
      iat: Time.now.to_i,
      exp: (Time.now - 60).to_i,
      sub: "session",
      iss: "barong",
      aud: [
        "peatio",
        "barong",
      ],
      jti: "BEF5617B7B2762DDE61702F5",
      uid: "TEST123",
      email: "user@example.com",
      role: "admin",
      level: 4,
      state: "active",
    }

    auth = Peatio::Auth::JWTAuthenticator.new(rsa_public, rsa_private)
    token = auth.encode(payload)

    expect {
      auth.authenticate!("Bearer #{token}")
    }.to raise_error(Peatio::Auth::Error)
  end

  it "will raise exception if no private key given for encoding" do
    rsa_private = OpenSSL::PKey::RSA.generate(2048)
    rsa_public = rsa_private.public_key

    auth = Peatio::Auth::JWTAuthenticator.new(rsa_public, nil)

    expect {
      token = auth.encode("xxx")
    }.to raise_error(ArgumentError)
  end
end
