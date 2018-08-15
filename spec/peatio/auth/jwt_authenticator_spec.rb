describe Peatio::Auth::JWTAuthenticator do
  it "can authenticate valid jwt" do
    rsa_private = OpenSSL::PKey::RSA.generate 2048
    rsa_public = rsa_private.public_key

    payload = {
      "iat": Time.now.to_i,
      "exp": (Time.now + 60).to_i,
      "sub": "session",
      "iss": "barong",
      "aud": [
        "peatio",
        "barong",
      ],
      "jti": "BEF5617B7B2762DDE61702F5",
      "uid": "TEST123",
      "email": "user@example.com",
      "role": "admin",
      "level": 4,
      "state": "active",
    }

    token = JWT.encode payload, rsa_private, "RS256"

    auth = Peatio::Auth::JWTAuthenticator.new("Bearer #{token}", rsa_public)
    auth.authenticate!
  end

  it "will raise exception for invalid jwt" do
    rsa_private = OpenSSL::PKey::RSA.generate 2048
    rsa_public = rsa_private.public_key

    # payload is expired
    payload = {
      "iat": Time.now.to_i,
      "exp": (Time.now - 60).to_i,
      "sub": "session",
      "iss": "barong",
      "aud": [
        "peatio",
        "barong",
      ],
      "jti": "BEF5617B7B2762DDE61702F5",
      "uid": "TEST123",
      "email": "user@example.com",
      "role": "admin",
      "level": 4,
      "state": "active",
    }

    token = JWT.encode payload, rsa_private, "RS256"

    auth = Peatio::Auth::JWTAuthenticator.new("Bearer #{token}", rsa_public)

    expect {
      auth.authenticate!
    }.to raise_error(Peatio::Auth::Error)
  end
end
